#![forbid(unsafe_op_in_unsafe_fn)]

use mongodb::{
    bson::{from_document, from_slice, to_document, to_vec, Bson, Document},
    error::Error as MongoError,
    options::{
        AggregateOptions, ClientOptions, Collation, DeleteOptions, FindOneOptions,
        FindOptions, Hint, InsertManyOptions, InsertOneOptions, ReadConcern, ReplaceOptions,
        UpdateModifications, UpdateOptions, WriteConcern,
    },
    results::{
        CollectionSpecification, DeleteResult, InsertManyResult, InsertOneResult, UpdateResult,
    },
    sync::{Client, ClientSession, Cursor},
    IndexModel, SearchIndexModel,
};
use std::{
    cell::RefCell,
    collections::{BTreeMap, HashMap},
    ffi::{c_char, c_int, c_uchar, CStr, CString},
    ptr,
    process::Command,
    sync::OnceLock,
    time::{Duration, Instant},
};

const ABI_VERSION: c_int = 3;
const DEFAULT_FFI_CURSOR_BATCH_SIZE: usize = 128;
const SLOW_OPERATION_LOG_THRESHOLD: Duration = Duration::from_millis(1_000);

pub struct MongoRustClient {
    client: Client,
    database_name: String,
    command_sessions: RefCell<HashMap<i64, CommandCursorState>>,
}

pub struct MongoRustCursor {
    kind: MongoRustCursorKind,
    batch_size: usize,
    pending: Option<Document>,
    exhausted: bool,
    label: &'static str,
}

enum MongoRustCursorKind {
    Documents(Cursor<Document>),
    CollectionSpecifications(Cursor<CollectionSpecification>),
    IndexModels(Cursor<IndexModel>),
}

struct CommandCursorState {
    session: ClientSession,
    metadata: CommandCursorMetadata,
}

#[derive(Clone)]
struct CommandCursorMetadata {
    label: String,
    slow_log_level: SlowLogLevel,
}

struct CommandLogContext {
    label: String,
    slow_log_level: SlowLogLevel,
}

#[derive(Clone, Copy)]
enum SlowLogLevel {
    Warn,
    Info,
    Off,
}

#[derive(Debug)]
struct GoogleDnsAnswer {
    data: String,
}

#[derive(Debug)]
struct ParsedMongoSrvUri {
    user_info: String,
    host: String,
    path: String,
    query_parameters: BTreeMap<String, String>,
    fragment: Option<String>,
}

enum CollectionActionError {
    Message(String),
    Mongo(MongoError),
}

type CollectionActionResult<T> = Result<T, CollectionActionError>;

#[no_mangle]
pub extern "C" fn mdd_rust_abi_version() -> c_int {
    ABI_VERSION
}

#[no_mangle]
pub extern "C" fn mdd_rust_string_free(value: *mut c_char) {
    if value.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(value));
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_bytes_free(value: *mut c_uchar, length: i32) {
    if value.is_null() || length <= 0 {
        return;
    }
    unsafe {
        drop(Vec::from_raw_parts(value, length as usize, length as usize));
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_open(
    uri: *const c_char,
    database_name: *const c_char,
    log_context: *const c_char,
    connect_timeout_ms: i64,
    server_selection_timeout_ms: i64,
    error_out: *mut *mut c_char,
) -> *mut MongoRustClient {
    match try_client_open(
        uri,
        database_name,
        log_context,
        connect_timeout_ms,
        server_selection_timeout_ms,
    ) {
        Ok(client) => Box::into_raw(Box::new(client)),
        Err(error) => {
            write_error(error_out, &error);
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_close(client: *mut MongoRustClient) {
    if client.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(client));
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_ping(
    client: *mut MongoRustClient,
    error_out: *mut *mut c_char,
) -> u8 {
    match try_client_ping(client) {
        Ok(()) => 1,
        Err(error) => {
            write_error(error_out, &error);
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_run_command_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
    result_bytes_out: *mut *mut c_uchar,
    result_len_out: *mut i32,
    error_out: *mut *mut c_char,
) -> u8 {
    match try_client_run_command_bson(client, request_bytes, request_len) {
        Ok(bytes) => {
            write_bytes_result(result_bytes_out, result_len_out, bytes);
            1
        }
        Err(error) => {
            write_error(error_out, &error);
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_execute_collection_action_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
    result_bytes_out: *mut *mut c_uchar,
    result_len_out: *mut i32,
    error_out: *mut *mut c_char,
) -> u8 {
    match try_client_execute_collection_action_bson(client, request_bytes, request_len) {
        Ok(bytes) => {
            write_bytes_result(result_bytes_out, result_len_out, bytes);
            1
        }
        Err(error) => {
            write_error(error_out, &error);
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_run_cursor_command_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
    result_bytes_out: *mut *mut c_uchar,
    result_len_out: *mut i32,
    error_out: *mut *mut c_char,
) -> u8 {
    match try_client_run_cursor_command_bson(client, request_bytes, request_len) {
        Ok(bytes) => {
            write_bytes_result(result_bytes_out, result_len_out, bytes);
            1
        }
        Err(error) => {
            write_error(error_out, &error);
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_find_one_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
    result_bytes_out: *mut *mut c_uchar,
    result_len_out: *mut i32,
    found_out: *mut u8,
    error_out: *mut *mut c_char,
) -> u8 {
    match try_client_find_one_bson(client, request_bytes, request_len) {
        Ok(Some(bytes)) => {
            let mut bytes = bytes;
            let len = bytes.len() as i32;
            let ptr = bytes.as_mut_ptr();
            std::mem::forget(bytes);
            unsafe {
                if !result_bytes_out.is_null() {
                    *result_bytes_out = ptr;
                }
                if !result_len_out.is_null() {
                    *result_len_out = len;
                }
                if !found_out.is_null() {
                    *found_out = 1;
                }
            }
            1
        }
        Ok(None) => {
            unsafe {
                if !result_bytes_out.is_null() {
                    *result_bytes_out = ptr::null_mut();
                }
                if !result_len_out.is_null() {
                    *result_len_out = 0;
                }
                if !found_out.is_null() {
                    *found_out = 0;
                }
            }
            1
        }
        Err(error) => {
            write_error(error_out, &error);
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_find_cursor_open_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
    error_out: *mut *mut c_char,
) -> *mut MongoRustCursor {
    match try_client_find_cursor_open_bson(client, request_bytes, request_len) {
        Ok(cursor) => Box::into_raw(Box::new(cursor)),
        Err(error) => {
            write_error(error_out, &error);
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_aggregate_cursor_open_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
    error_out: *mut *mut c_char,
) -> *mut MongoRustCursor {
    match try_client_aggregate_cursor_open_bson(client, request_bytes, request_len) {
        Ok(cursor) => Box::into_raw(Box::new(cursor)),
        Err(error) => {
            write_error(error_out, &error);
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_cursor_next_batch_bson(
    cursor: *mut MongoRustCursor,
    result_bytes_out: *mut *mut c_uchar,
    result_len_out: *mut i32,
    exhausted_out: *mut u8,
    error_out: *mut *mut c_char,
) -> u8 {
    match try_cursor_next_batch_bson(cursor) {
        Ok((bytes, exhausted)) => {
            if let Some(bytes) = bytes {
                write_bytes_result(result_bytes_out, result_len_out, bytes);
            } else {
                unsafe {
                    if !result_bytes_out.is_null() {
                        *result_bytes_out = ptr::null_mut();
                    }
                    if !result_len_out.is_null() {
                        *result_len_out = 0;
                    }
                }
            }
            unsafe {
                if !exhausted_out.is_null() {
                    *exhausted_out = if exhausted { 1 } else { 0 };
                }
            }
            1
        }
        Err(error) => {
            write_error(error_out, &error);
            0
        }
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_cursor_close(cursor: *mut MongoRustCursor) {
    if cursor.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(cursor));
    }
}

#[no_mangle]
pub extern "C" fn mdd_rust_client_aggregate_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
    result_bytes_out: *mut *mut c_uchar,
    result_len_out: *mut i32,
    error_out: *mut *mut c_char,
) -> u8 {
    match try_client_aggregate_bson(client, request_bytes, request_len) {
        Ok(bytes) => {
            write_bytes_result(result_bytes_out, result_len_out, bytes);
            1
        }
        Err(error) => {
            write_error(error_out, &error);
            0
        }
    }
}

impl MongoRustCursor {
    fn new_document(cursor: Cursor<Document>, batch_size: usize, label: &'static str) -> Self {
        Self {
            kind: MongoRustCursorKind::Documents(cursor),
            batch_size: batch_size.max(1),
            pending: None,
            exhausted: false,
            label,
        }
    }

    fn new_collection_specifications(
        cursor: Cursor<CollectionSpecification>,
        batch_size: usize,
        label: &'static str,
    ) -> Self {
        Self {
            kind: MongoRustCursorKind::CollectionSpecifications(cursor),
            batch_size: batch_size.max(1),
            pending: None,
            exhausted: false,
            label,
        }
    }

    fn new_index_models(
        cursor: Cursor<IndexModel>,
        batch_size: usize,
        label: &'static str,
    ) -> Self {
        Self {
            kind: MongoRustCursorKind::IndexModels(cursor),
            batch_size: batch_size.max(1),
            pending: None,
            exhausted: false,
            label,
        }
    }

    fn next_document(&mut self) -> Option<Result<Document, String>> {
        match &mut self.kind {
            MongoRustCursorKind::Documents(cursor) => cursor
                .next()
                .map(|result| result.map_err(|error| error.to_string())),
            MongoRustCursorKind::CollectionSpecifications(cursor) => cursor.next().map(|result| {
                result
                    .map_err(|error| error.to_string())
                    .and_then(|specification| {
                        to_document(&specification)
                            .map_err(|error| format!("listCollections BSON encode failed: {error}"))
                    })
            }),
            MongoRustCursorKind::IndexModels(cursor) => cursor.next().map(|result| {
                result
                    .map_err(|error| error.to_string())
                    .and_then(|index_model| {
                        to_document(&index_model)
                            .map_err(|error| format!("listIndexes BSON encode failed: {error}"))
                    })
            }),
        }
    }

    fn next_batch(&mut self) -> Result<Vec<Document>, String> {
        let started_at = Instant::now();
        let result = (|| {
            if self.exhausted {
                return Ok(Vec::new());
            }

            let mut documents = Vec::with_capacity(self.batch_size);
            if let Some(document) = self.pending.take() {
                documents.push(document);
            }

            while documents.len() < self.batch_size {
                match self.next_document() {
                    Some(Ok(document)) => documents.push(document),
                    Some(Err(error)) => {
                        return Err(format!("{} cursor read failed: {error}", self.label));
                    }
                    None => {
                        self.exhausted = true;
                        break;
                    }
                }
            }

            if !self.exhausted && documents.len() >= self.batch_size {
                match self.next_document() {
                    Some(Ok(document)) => {
                        self.pending = Some(document);
                    }
                    Some(Err(error)) => {
                        return Err(format!("{} cursor read failed: {error}", self.label));
                    }
                    None => {
                        self.exhausted = true;
                    }
                }
            }

            Ok(documents)
        })();
        log_slow_operation(&format!("{} cursor nextBatch", self.label), started_at);
        result
    }

    fn collect_all(mut self) -> Result<Vec<Document>, String> {
        let mut documents = Vec::new();
        loop {
            let batch = self.next_batch()?;
            if batch.is_empty() {
                break;
            }
            documents.extend(batch);
            if self.exhausted {
                break;
            }
        }
        Ok(documents)
    }
}

fn try_client_open(
    uri: *const c_char,
    database_name: *const c_char,
    log_context: *const c_char,
    connect_timeout_ms: i64,
    server_selection_timeout_ms: i64,
) -> Result<MongoRustClient, String> {
    let started_at = Instant::now();
    let uri = read_c_string(uri, "uri")?;
    let database_name = read_c_string(database_name, "database_name")?;
    let log_context = read_c_string(log_context, "log_context")?;
    let resolved_uri = expand_srv_connection_string(uri.as_str())?;

    let mut options = ClientOptions::parse(resolved_uri.as_str())
        .run()
        .map_err(|error| format!("{log_context} client options parse failed: {error}"))?;
    let min_pool_size = options.min_pool_size.unwrap_or(0);
    if connect_timeout_ms > 0 {
        options.connect_timeout = Some(Duration::from_millis(connect_timeout_ms as u64));
    }
    if server_selection_timeout_ms > 0 {
        options.server_selection_timeout =
            Some(Duration::from_millis(server_selection_timeout_ms as u64));
    }

    let client = Client::with_options(options)
        .map_err(|error| format!("{log_context} client creation failed: {error}"))?;
    client
        .database("admin")
        .run_command(Document::from_iter([("ping".to_string(), Bson::Int32(1))]))
        .run()
        .map_err(|error| format!("{log_context} initial connectivity check failed: {error}"))?;
    log_rust_info(&format!(
        "{log_context} connected to MongoDB database {} in {}ms",
        database_name,
        started_at.elapsed().as_millis()
    ));
    if min_pool_size > 0 {
        let warm_client = client.clone();
        std::thread::spawn(move || {
            let _ = warm_client.warm_connection_pool().run();
        });
    }
    Ok(MongoRustClient {
        client,
        database_name,
        command_sessions: RefCell::new(HashMap::new()),
    })
}

fn expand_srv_connection_string(uri: &str) -> Result<String, String> {
    if !uri.starts_with("mongodb+srv://") {
        return Ok(uri.to_string());
    }

    let parsed = parse_mongodb_srv_uri(uri)?;
    if parsed.host.contains(',') {
        return Err("MongoDB SRV URI must contain exactly one seed host.".to_string());
    }

    let srv_answers = resolve_google_dns(&format!("_mongodb._tcp.{}", parsed.host), 33)?;
    if srv_answers.is_empty() {
        return Err("MongoDB SRV DNS resolution returned no SRV records.".to_string());
    }
    let txt_answers = resolve_google_dns(parsed.host.as_str(), 16)?;
    if txt_answers.len() > 1 {
        return Err("MongoDB SRV DNS returned multiple TXT records; expected at most one.".to_string());
    }

    let mut query_parameters = parse_query_parameters(
        txt_answers.first().map(|answer| answer.data.as_str()).unwrap_or(""),
    );
    for (key, value) in parsed.query_parameters {
        query_parameters.insert(key, value);
    }
    if !query_parameters.contains_key("tls") && !query_parameters.contains_key("ssl") {
        query_parameters.insert("tls".to_string(), "true".to_string());
    }

    let hosts = srv_answers
        .iter()
        .map(|answer| parse_srv_record(parsed.host.as_str(), answer.data.as_str()))
        .collect::<Result<Vec<_>, _>>()?
        .join(",");

    let mut expanded = format!("mongodb://{}{hosts}{}", parsed.user_info, parsed.path);
    let query = serialize_query_parameters(&query_parameters);
    if !query.is_empty() {
        expanded.push('?');
        expanded.push_str(&query);
    }
    if let Some(fragment) = parsed.fragment {
        expanded.push('#');
        expanded.push_str(fragment.as_str());
    }
    Ok(expanded)
}

fn resolve_google_dns(name: &str, record_type: u16) -> Result<Vec<GoogleDnsAnswer>, String> {
    let url = format!(
        "https://dns.google.com/resolve?name={name}&type={record_type}&dnssec=false"
    );
    let output = Command::new("curl")
        .args(["-sSfL", url.as_str()])
        .output()
        .map_err(|error| format!("Could not execute curl for DNS lookup: {error}"))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!(
            "DNS HTTPS lookup failed for {name} type {record_type}: {}",
            stderr.trim()
        ));
    }
    let payload = String::from_utf8(output.stdout)
        .map_err(|error| format!("Could not decode DNS response as UTF-8: {error}"))?;
    let status = extract_json_status(payload.as_str())?;
    if status != 0 {
        if record_type == 16 {
            return Ok(Vec::new());
        }
        return Err(format!(
            "DNS lookup failed for {name} type {record_type} with status {}.",
            status
        ));
    }
    Ok(extract_json_data_values(payload.as_str())
        .into_iter()
        .map(|data| GoogleDnsAnswer { data })
        .collect())
}

fn parse_query_parameters(raw: &str) -> BTreeMap<String, String> {
    let cleaned = raw.trim().replace('"', "");
    if cleaned.is_empty() {
        return BTreeMap::new();
    }
    cleaned
        .split('&')
        .filter(|entry| !entry.is_empty())
        .filter_map(|entry| {
            let (key, value) = entry.split_once('=').unwrap_or((entry, ""));
            if key.is_empty() {
                return None;
            }
            Some((key.to_string(), value.to_string()))
        })
        .collect()
}

fn serialize_query_parameters(parameters: &BTreeMap<String, String>) -> String {
    parameters
        .iter()
        .map(|(key, value)| format!("{key}={value}"))
        .collect::<Vec<_>>()
        .join("&")
}

fn parse_srv_record(seed_host: &str, raw_record: &str) -> Result<String, String> {
    let mut parts = raw_record.split_whitespace();
    let _priority = parts.next();
    let _weight = parts.next();
    let port = parts
        .next()
        .ok_or_else(|| format!("Invalid MongoDB SRV record: {raw_record}"))?;
    let target = parts
        .next()
        .ok_or_else(|| format!("Invalid MongoDB SRV record: {raw_record}"))?
        .trim_end_matches('.');
    validate_srv_target_domain(seed_host, target)?;
    Ok(format!("{target}:{port}"))
}

fn validate_srv_target_domain(seed_host: &str, target: &str) -> Result<(), String> {
    let suffix = seed_host
        .split_once('.')
        .map(|(_, suffix)| suffix)
        .ok_or_else(|| format!("MongoDB SRV host {seed_host} is not a valid domain."))?;
    if target == suffix || target.ends_with(&format!(".{suffix}")) {
        return Ok(());
    }
    Err(format!(
        "Different domain detected in MongoDB SRV record: required suffix {suffix}, got {target}."
    ))
}

fn parse_mongodb_srv_uri(uri: &str) -> Result<ParsedMongoSrvUri, String> {
    let without_scheme = uri
        .strip_prefix("mongodb+srv://")
        .ok_or_else(|| "MongoDB SRV URI must start with mongodb+srv://".to_string())?;
    let (base_without_fragment, fragment) = match without_scheme.split_once('#') {
        Some((base, fragment)) => (base, Some(fragment.to_string())),
        None => (without_scheme, None),
    };
    let (authority_and_path, query) = match base_without_fragment.split_once('?') {
        Some((authority_and_path, query)) => (authority_and_path, query),
        None => (base_without_fragment, ""),
    };
    let (authority, path) = match authority_and_path.find('/') {
        Some(index) => (&authority_and_path[..index], &authority_and_path[index..]),
        None => (authority_and_path, "/"),
    };
    if authority.is_empty() {
        return Err("MongoDB SRV URI is missing an authority section.".to_string());
    }
    let (user_info, host) = match authority.rsplit_once('@') {
        Some((credentials, host)) => (format!("{credentials}@"), host),
        None => (String::new(), authority),
    };
    if host.is_empty() {
        return Err("MongoDB SRV URI is missing a host.".to_string());
    }
    Ok(ParsedMongoSrvUri {
        user_info,
        host: host.to_string(),
        path: if path.is_empty() {
            "/".to_string()
        } else {
            path.to_string()
        },
        query_parameters: parse_query_parameters(query),
        fragment,
    })
}

fn extract_json_status(json: &str) -> Result<u32, String> {
    let key = "\"Status\":";
    let start = json
        .find(key)
        .ok_or_else(|| "DNS JSON response is missing a Status field.".to_string())?
        + key.len();
    let digits: String = json[start..]
        .chars()
        .skip_while(|character| character.is_whitespace())
        .take_while(|character| character.is_ascii_digit())
        .collect();
    if digits.is_empty() {
        return Err("DNS JSON Status field was not numeric.".to_string());
    }
    digits
        .parse::<u32>()
        .map_err(|error| format!("Could not parse DNS Status field: {error}"))
}

fn extract_json_data_values(json: &str) -> Vec<String> {
    let mut values = Vec::new();
    let needle = "\"data\":\"";
    let mut search_index = 0usize;
    while let Some(relative_start) = json[search_index..].find(needle) {
        let mut index = search_index + relative_start + needle.len();
        let mut value = String::new();
        let mut escaped = false;
        while index < json.len() {
            let character = json.as_bytes()[index] as char;
            index += 1;
            if escaped {
                match character {
                    '"' | '\\' | '/' => value.push(character),
                    'b' => value.push('\u{0008}'),
                    'f' => value.push('\u{000C}'),
                    'n' => value.push('\n'),
                    'r' => value.push('\r'),
                    't' => value.push('\t'),
                    'u' => {
                        if index + 4 <= json.len() {
                            let hex = &json[index..index + 4];
                            if let Ok(codepoint) = u16::from_str_radix(hex, 16) {
                                if let Some(decoded) = char::from_u32(codepoint as u32) {
                                    value.push(decoded);
                                }
                            }
                            index += 4;
                        }
                    }
                    _ => value.push(character),
                }
                escaped = false;
                continue;
            }
            if character == '\\' {
                escaped = true;
                continue;
            }
            if character == '"' {
                break;
            }
            value.push(character);
        }
        values.push(value);
        search_index = index;
    }
    values
}

fn try_client_ping(client: *mut MongoRustClient) -> Result<(), String> {
    let client = client_ref(client)?;
    client
        .client
        .database("admin")
        .run_command(Document::from_iter([("ping".to_string(), Bson::Int32(1))]))
        .run()
        .map_err(|error| format!("Ping failed: {error}"))?;
    Ok(())
}

fn try_client_run_command_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
) -> Result<Vec<u8>, String> {
    let client = client_ref(client)?;
    let mut request = read_bson_document(request_bytes, request_len, "command request")?;
    let command_log_context = describe_command_log_context(client, &request)?;
    let command_label = command_log_context.label.clone();
    let started_at = Instant::now();
    let database_name = request_database_name(client, &mut request)?;
    let result = if let Some(bytes) = try_run_special_command(client, &database_name, &request)? {
        Ok(bytes)
    } else {
        let response =
            run_command_with_cursor_session(client, &database_name, request, &command_label)?;
        to_vec(&response).map_err(|error| format!("{command_label} BSON encode failed: {error}"))
    };
    log_slow_operation_with_level(
        &command_label,
        started_at,
        command_log_context.slow_log_level,
    );
    result
}

fn run_command_with_cursor_session(
    client: &MongoRustClient,
    database_name: &str,
    request: Document,
    command_label: &str,
) -> Result<Document, String> {
    if let Some(cursor_id) = read_get_more_command_cursor_id(&request)? {
        return run_get_more_with_stored_session(
            client,
            database_name,
            request,
            cursor_id,
            command_label,
        );
    }

    if let Some(cursor_ids) = read_kill_cursors_command_cursor_ids(&request)? {
        return run_kill_cursors_with_stored_session(
            client,
            database_name,
            request,
            &cursor_ids,
            command_label,
        );
    }

    if command_starts_cursor_session(&request) {
        let metadata = command_cursor_metadata_for_request(&request);
        let mut session = client
            .client
            .start_session()
            .run()
            .map_err(|error| format!("{command_label} session start failed: {error}"))?;
        let response = client
            .client
            .database(database_name)
            .run_command(request)
            .session(&mut session)
            .run()
            .map_err(|error| format!("{command_label} failed: {error}"))?;
        track_command_session_from_response(client, &response, session, metadata)?;
        return Ok(response);
    }

    run_plain_command(client, database_name, request, command_label)
}

fn run_plain_command(
    client: &MongoRustClient,
    database_name: &str,
    request: Document,
    command_label: &str,
) -> Result<Document, String> {
    client
        .client
        .database(database_name)
        .run_command(request)
        .run()
        .map_err(|error| format!("{command_label} failed: {error}"))
}

fn run_get_more_with_stored_session(
    client: &MongoRustClient,
    database_name: &str,
    request: Document,
    cursor_id: i64,
    command_label: &str,
) -> Result<Document, String> {
    let stored_state = client.command_sessions.borrow_mut().remove(&cursor_id);
    let Some(mut state) = stored_state else {
        return run_plain_command(client, database_name, request, command_label);
    };

    let result = client
        .client
        .database(database_name)
        .run_command(request)
        .session(&mut state.session)
        .run()
        .map_err(|error| format!("{command_label} failed: {error}"));

    match result {
        Ok(response) => {
            update_stored_command_session(client, &response, state)?;
            Ok(response)
        }
        Err(error) => {
            client.command_sessions.borrow_mut().insert(cursor_id, state);
            Err(error)
        }
    }
}

fn run_kill_cursors_with_stored_session(
    client: &MongoRustClient,
    database_name: &str,
    request: Document,
    cursor_ids: &[i64],
    command_label: &str,
) -> Result<Document, String> {
    let session_cursor_id = {
        let command_sessions = client.command_sessions.borrow();
        cursor_ids
            .iter()
            .copied()
            .find(|cursor_id| command_sessions.contains_key(cursor_id))
    };

    let response = if let Some(session_cursor_id) = session_cursor_id {
        let mut state = match client.command_sessions.borrow_mut().remove(&session_cursor_id) {
            Some(state) => state,
            None => return run_plain_command(client, database_name, request, command_label),
        };
        let result = client
            .client
            .database(database_name)
            .run_command(request)
            .session(&mut state.session)
            .run()
            .map_err(|error| format!("{command_label} failed: {error}"));
        match result {
            Ok(response) => response,
            Err(error) => {
                client
                    .command_sessions
                    .borrow_mut()
                    .insert(session_cursor_id, state);
                return Err(error);
            }
        }
    } else {
        run_plain_command(client, database_name, request, command_label)?
    };

    let mut command_sessions = client.command_sessions.borrow_mut();
    for cursor_id in cursor_ids {
        command_sessions.remove(cursor_id);
    }
    Ok(response)
}

fn describe_command_log_context(
    client: &MongoRustClient,
    request: &Document,
) -> Result<CommandLogContext, String> {
    if let Some(cursor_id) = read_get_more_command_cursor_id(request)? {
        if let Some(state) = client.command_sessions.borrow().get(&cursor_id) {
            return Ok(CommandLogContext {
                label: format!("{} getMore", state.metadata.label),
                slow_log_level: state.metadata.slow_log_level,
            });
        }
    }

    if let Some(cursor_ids) = read_kill_cursors_command_cursor_ids(request)? {
        if let Some(metadata) = {
            let command_sessions = client.command_sessions.borrow();
            cursor_ids
                .iter()
                .find_map(|cursor_id| {
                    command_sessions
                        .get(cursor_id)
                        .map(|state| state.metadata.clone())
                })
        } {
            return Ok(CommandLogContext {
                label: format!("{} killCursors", metadata.label),
                slow_log_level: SlowLogLevel::Warn,
            });
        }
    }

    let metadata = command_cursor_metadata_for_request(request);
    Ok(CommandLogContext {
        label: metadata.label,
        slow_log_level: metadata.slow_log_level,
    })
}

fn command_cursor_metadata_for_request(request: &Document) -> CommandCursorMetadata {
    if let Ok(collection_name) = request.get_str("aggregate") {
        if is_change_stream_aggregate_command(request) {
            return CommandCursorMetadata {
                label: format!("changeStream {collection_name}"),
                slow_log_level: if should_log_change_stream_slow_operations() {
                    SlowLogLevel::Info
                } else {
                    SlowLogLevel::Off
                },
            };
        }
        return CommandCursorMetadata {
            label: format!("aggregate {collection_name}"),
            slow_log_level: SlowLogLevel::Warn,
        };
    }

    if let Ok(collection_name) = request.get_str("find") {
        return CommandCursorMetadata {
            label: format!("find {collection_name}"),
            slow_log_level: SlowLogLevel::Warn,
        };
    }

    CommandCursorMetadata {
        label: describe_command(request),
        slow_log_level: SlowLogLevel::Warn,
    }
}

fn is_change_stream_aggregate_command(request: &Document) -> bool {
    let Ok(pipeline) = request.get_array("pipeline") else {
        return false;
    };
    let Some(Bson::Document(first_stage)) = pipeline.first() else {
        return false;
    };
    first_stage.contains_key("$changeStream")
}

fn should_log_change_stream_slow_operations() -> bool {
    static SHOULD_LOG: OnceLock<bool> = OnceLock::new();
    *SHOULD_LOG.get_or_init(|| read_enabled_env("MONGO_DOCUMENT_DB_RUST_LOG_CHANGE_STREAM_SLOW_OPS"))
}

fn read_enabled_env(name: &str) -> bool {
    let Ok(value) = std::env::var(name) else {
        return false;
    };
    matches!(
        value.trim().to_ascii_lowercase().as_str(),
        "1" | "true" | "yes" | "on"
    )
}

fn track_command_session_from_response(
    client: &MongoRustClient,
    response: &Document,
    session: ClientSession,
    metadata: CommandCursorMetadata,
) -> Result<(), String> {
    let Some(cursor_id) = response_cursor_id(response)? else {
        return Ok(());
    };
    if cursor_id == 0 {
        return Ok(());
    }
    client
        .command_sessions
        .borrow_mut()
        .insert(cursor_id, CommandCursorState { session, metadata });
    Ok(())
}

fn update_stored_command_session(
    client: &MongoRustClient,
    response: &Document,
    state: CommandCursorState,
) -> Result<(), String> {
    let Some(cursor_id) = response_cursor_id(response)? else {
        return Ok(());
    };
    if cursor_id == 0 {
        return Ok(());
    }
    client.command_sessions.borrow_mut().insert(cursor_id, state);
    Ok(())
}

fn command_starts_cursor_session(request: &Document) -> bool {
    request.contains_key("aggregate") || request.contains_key("find")
}

fn response_cursor_id(response: &Document) -> Result<Option<i64>, String> {
    let cursor = match response.get_document("cursor") {
        Ok(cursor) => cursor,
        Err(_) => return Ok(None),
    };
    if !cursor.contains_key("id") {
        return Ok(None);
    }
    Ok(Some(read_cursor_id(cursor.get("id"))?))
}

fn read_get_more_command_cursor_id(request: &Document) -> Result<Option<i64>, String> {
    if !request.contains_key("getMore") {
        return Ok(None);
    }
    Ok(Some(read_cursor_id(request.get("getMore"))?))
}

fn read_kill_cursors_command_cursor_ids(request: &Document) -> Result<Option<Vec<i64>>, String> {
    if !request.contains_key("killCursors") {
        return Ok(None);
    }
    let cursor_values = request
        .get_array("cursors")
        .map_err(|error| format!("killCursors missing cursors: {error}"))?;
    let mut cursor_ids = Vec::with_capacity(cursor_values.len());
    for value in cursor_values {
        cursor_ids.push(read_cursor_id(Some(value))?);
    }
    Ok(Some(cursor_ids))
}

fn try_run_special_command(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<Option<Vec<u8>>, String> {
    if request.contains_key("listCollections") {
        let documents = execute_list_collections_documents(client, database_name, request)?;
        return Ok(Some(encode_cursor_response(
            database_name,
            r"$cmd.listCollections",
            documents,
        )?));
    }

    if let Ok(collection_name) = request.get_str("listIndexes") {
        let documents = execute_list_indexes_documents(
            client,
            database_name,
            collection_name,
            request,
        )?;
        return Ok(Some(encode_cursor_response(
            database_name,
            collection_name,
            documents,
        )?));
    }

    if let Ok(collection_name) = request.get_str("listSearchIndexes") {
        let collection = client
            .client
            .database(database_name)
            .collection::<Document>(collection_name);
        let mut action = collection.list_search_indexes();
        if let Ok(name) = request.get_str("name") {
            action = action.name(name);
        }
        let cursor = action
            .run()
            .map_err(|error| format!("listSearchIndexes failed: {error}"))?;
        let mut documents = Vec::new();
        for result in cursor {
            let document =
                result.map_err(|error| format!("listSearchIndexes cursor failed: {error}"))?;
            documents.push(document);
        }
        return Ok(Some(encode_search_index_cursor_response(
            database_name,
            collection_name,
            documents,
        )?));
    }

    if let Ok(collection_name) = request.get_str("createSearchIndexes") {
        let indexes = request
            .get_array("indexes")
            .map_err(|error| format!("createSearchIndexes missing indexes: {error}"))?;
        let mut models = Vec::with_capacity(indexes.len());
        for index in indexes {
            let document = match index {
                Bson::Document(document) => document.clone(),
                _ => return Err("createSearchIndexes indexes entry was not a document".to_string()),
            };
            let model = from_document::<SearchIndexModel>(document)
                .map_err(|error| format!("createSearchIndexes index decode failed: {error}"))?;
            models.push(model);
        }
        let collection = client
            .client
            .database(database_name)
            .collection::<Document>(collection_name);
        let created_names = collection
            .create_search_indexes(models)
            .run()
            .map_err(|error| format!("createSearchIndexes failed: {error}"))?;
        return Ok(Some(encode_create_search_indexes_response(created_names)?));
    }

    if let Ok(collection_name) = request.get_str("updateSearchIndex") {
        let name = request
            .get_str("name")
            .map_err(|error| format!("updateSearchIndex missing name: {error}"))?;
        let definition = request
            .get_document("definition")
            .map_err(|error| format!("updateSearchIndex missing definition: {error}"))?
            .clone();
        let collection = client
            .client
            .database(database_name)
            .collection::<Document>(collection_name);
        collection
            .update_search_index(name, definition)
            .run()
            .map_err(|error| format!("updateSearchIndex failed: {error}"))?;
        return Ok(Some(encode_ok_response()));
    }

    if let Ok(collection_name) = request.get_str("dropSearchIndex") {
        let name = request
            .get_str("name")
            .map_err(|error| format!("dropSearchIndex missing name: {error}"))?;
        let collection = client
            .client
            .database(database_name)
            .collection::<Document>(collection_name);
        collection
            .drop_search_index(name)
            .run()
            .map_err(|error| format!("dropSearchIndex failed: {error}"))?;
        return Ok(Some(encode_ok_response()));
    }

    Ok(None)
}

fn try_client_run_cursor_command_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
) -> Result<Vec<u8>, String> {
    let client = client_ref(client)?;
    let mut request = read_bson_document(request_bytes, request_len, "cursor command request")?;
    let command_label = describe_command(&request);
    let started_at = Instant::now();
    let database_name = request_database_name(client, &mut request)?;
    let result = if let Some(bytes) = try_run_special_cursor_command(client, &database_name, &request)? {
        Ok(bytes)
    } else {
        let batch_size = read_command_batch_size(&request);
        let response = client
            .client
            .database(&database_name)
            .run_command(request)
            .run()
            .map_err(|error| format!("{command_label} failed: {error}"))?;
        let documents = collect_cursor_documents(client, response, batch_size)?;
        encode_document_list(documents, &command_label)
    };
    log_slow_operation(&command_label, started_at);
    result
}

fn try_run_special_cursor_command(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<Option<Vec<u8>>, String> {
    if request.get_str("find").is_ok() {
        let documents = execute_find_documents(client, database_name, request)?;
        return Ok(Some(encode_document_list(documents, "find")?));
    }
    if request.get_str("aggregate").is_ok() {
        let documents = execute_aggregate_documents(client, database_name, request)?;
        return Ok(Some(encode_document_list(documents, "aggregate")?));
    }
    Ok(None)
}

fn try_client_find_one_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
) -> Result<Option<Vec<u8>>, String> {
    let client = client_ref(client)?;
    let mut request = read_bson_document(request_bytes, request_len, "findOne request")?;
    let database_name = request_database_name(client, &mut request)?;
    let collection_name = request
        .get_str("collection")
        .map_err(|error| format!("findOne request missing collection: {error}"))?;
    let operation_label = format!("findOne {collection_name}");
    let started_at = Instant::now();

    let filter = match request.get_document("filter") {
        Ok(document) => document.clone(),
        Err(_) => Document::new(),
    };
    let collection = client
        .client
        .database(&database_name)
        .collection::<Document>(collection_name);

    let mut options = FindOneOptions::default();
    if let Ok(projection) = request.get_document("projection") {
        options.projection = Some(projection.clone());
    }
    if let Ok(sort) = request.get_document("sort") {
        options.sort = Some(sort.clone());
    }
    if let Ok(hint_name) = request.get_str("hint") {
        options.hint = Some(Hint::Name(hint_name.to_string()));
    } else if let Ok(hint_document) = request.get_document("hintDocument") {
        options.hint = Some(Hint::Keys(hint_document.clone()));
    }
    if let Some(skip) = read_i64_value(&request, "skip") {
        if skip > 0 {
            options.skip = Some(skip as u64);
        }
    }
    if let Some(max_time_ms) = read_i64_value(&request, "maxTimeMS") {
        if max_time_ms > 0 {
            options.max_time = Some(Duration::from_millis(max_time_ms as u64));
        }
    }

    let result = collection
        .find_one(filter)
        .with_options(options)
        .run()
        .map_err(|error| format!("{operation_label} failed: {error}"))?;
    let result = result
        .map(|document| to_vec(&document).map_err(|error| format!("BSON encode failed: {error}")))
        .transpose();
    log_slow_operation(&operation_label, started_at);
    result
}

fn try_client_find_cursor_open_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
) -> Result<MongoRustCursor, String> {
    let client = client_ref(client)?;
    let mut request = read_bson_document(request_bytes, request_len, "find cursor request")?;
    let database_name = request_database_name(client, &mut request)?;
    open_find_cursor(client, &database_name, &request)
}

fn try_client_aggregate_cursor_open_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
) -> Result<MongoRustCursor, String> {
    let client = client_ref(client)?;
    let mut request = read_bson_document(request_bytes, request_len, "aggregate cursor request")?;
    let database_name = request_database_name(client, &mut request)?;
    open_aggregate_cursor(client, &database_name, &request)
}

fn try_cursor_next_batch_bson(
    cursor: *mut MongoRustCursor,
) -> Result<(Option<Vec<u8>>, bool), String> {
    let cursor = cursor_ref_mut(cursor)?;
    let documents = cursor.next_batch()?;
    let exhausted = cursor.exhausted;
    if documents.is_empty() {
        return Ok((None, exhausted));
    }
    Ok((Some(encode_document_list(documents, cursor.label)?), exhausted))
}

fn try_client_aggregate_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
) -> Result<Vec<u8>, String> {
    let client = client_ref(client)?;
    let mut request = read_bson_document(request_bytes, request_len, "aggregate request")?;
    let database_name = request_database_name(client, &mut request)?;
    let documents = open_aggregate_cursor(client, &database_name, &request)?.collect_all()?;
    encode_document_list(documents, "aggregate")
}

fn try_client_execute_collection_action_bson(
    client: *mut MongoRustClient,
    request_bytes: *const c_uchar,
    request_len: i32,
) -> Result<Vec<u8>, String> {
    let client = client_ref(client)?;
    let mut request =
        read_bson_document(request_bytes, request_len, "collection action request")?;
    let database_name = request_database_name(client, &mut request)?;
    let action = request
        .get_str("action")
        .map_err(|error| format!("collection action request missing action: {error}"))?;
    let collection_name = request
        .get_str("collection")
        .map_err(|error| format!("{action} request missing collection: {error}"))?;
    let operation_label = format!("{action} {collection_name}");
    let started_at = Instant::now();

    let result = match action {
        "insertOne" => execute_insert_one_action(client, &database_name, collection_name, &request),
        "insertMany" => {
            execute_insert_many_action(client, &database_name, collection_name, &request)
        }
        "replaceOne" => {
            execute_replace_one_action(client, &database_name, collection_name, &request)
        }
        "updateOne" => execute_update_action(
            client,
            &database_name,
            collection_name,
            &request,
            false,
        ),
        "updateMany" => execute_update_action(
            client,
            &database_name,
            collection_name,
            &request,
            true,
        ),
        "deleteOne" => execute_delete_action(
            client,
            &database_name,
            collection_name,
            &request,
            false,
        ),
        "deleteMany" => execute_delete_action(
            client,
            &database_name,
            collection_name,
            &request,
            true,
        ),
        _ => Err(CollectionActionError::Message(format!(
            "Unsupported collection action: {action}"
        ))),
    };

    let result = match result {
        Ok(bytes) => Ok(bytes),
        Err(CollectionActionError::Mongo(error)) => collection_action_error_response(&error)
            .ok_or_else(|| format!("{operation_label} failed: {error}")),
        Err(CollectionActionError::Message(message)) => Err(message),
    };
    log_slow_operation(&operation_label, started_at);
    result
}

fn execute_insert_one_action(
    client: &MongoRustClient,
    database_name: &str,
    collection_name: &str,
    request: &Document,
) -> CollectionActionResult<Vec<u8>> {
    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);
    let document = request
        .get_document("document")
        .map_err(|error| {
            CollectionActionError::Message(format!("insertOne request missing document: {error}"))
        })?
        .clone();

    let mut options = InsertOneOptions::default();
    options.write_concern = read_write_concern(request, "insertOne")?;
    if let Ok(bypass_document_validation) = request.get_bool("bypassDocumentValidation") {
        options.bypass_document_validation = Some(bypass_document_validation);
    }
    let result = collection
        .insert_one(document)
        .with_options(options)
        .run()
        .map_err(CollectionActionError::Mongo)?;
    encode_insert_one_action_result(&result).map_err(CollectionActionError::Message)
}

fn execute_insert_many_action(
    client: &MongoRustClient,
    database_name: &str,
    collection_name: &str,
    request: &Document,
) -> CollectionActionResult<Vec<u8>> {
    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);
    let documents = read_document_array_field(request, "documents", "insertMany")?;

    let mut options = InsertManyOptions::default();
    options.write_concern = read_write_concern(request, "insertMany")?;
    if let Ok(ordered) = request.get_bool("ordered") {
        options.ordered = Some(ordered);
    }
    if let Ok(bypass_document_validation) = request.get_bool("bypassDocumentValidation") {
        options.bypass_document_validation = Some(bypass_document_validation);
    }
    let result = collection
        .insert_many(documents)
        .with_options(options)
        .run()
        .map_err(CollectionActionError::Mongo)?;
    encode_insert_many_action_result(&result).map_err(CollectionActionError::Message)
}

fn execute_replace_one_action(
    client: &MongoRustClient,
    database_name: &str,
    collection_name: &str,
    request: &Document,
) -> CollectionActionResult<Vec<u8>> {
    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);
    let filter = request
        .get_document("filter")
        .map_err(|error| {
            CollectionActionError::Message(format!("replaceOne request missing filter: {error}"))
        })?
        .clone();
    let replacement = request
        .get_document("replacement")
        .map_err(|error| {
            CollectionActionError::Message(format!(
                "replaceOne request missing replacement: {error}"
            ))
        })?
        .clone();

    let mut options = ReplaceOptions::default();
    options.write_concern = read_write_concern(request, "replaceOne")?;
    options.collation = read_collation(request, "replaceOne")?;
    options.hint = read_hint(request);
    if let Ok(upsert) = request.get_bool("upsert") {
        options.upsert = Some(upsert);
    }
    let result = collection
        .replace_one(filter, replacement)
        .with_options(options)
        .run()
        .map_err(CollectionActionError::Mongo)?;
    encode_update_action_result(&result, "replaceOne").map_err(CollectionActionError::Message)
}

fn execute_update_action(
    client: &MongoRustClient,
    database_name: &str,
    collection_name: &str,
    request: &Document,
    multi: bool,
) -> CollectionActionResult<Vec<u8>> {
    let action_label = if multi { "updateMany" } else { "updateOne" };
    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);
    let filter = request
        .get_document("filter")
        .map_err(|error| {
            CollectionActionError::Message(format!("{action_label} request missing filter: {error}"))
        })?
        .clone();
    let update = read_update_modifications(request, "update", action_label)?;

    let mut options = UpdateOptions::default();
    options.write_concern = read_write_concern(request, action_label)?;
    options.collation = read_collation(request, action_label)?;
    options.hint = read_hint(request);
    options.array_filters = read_document_array_field_optional(request, "arrayFilters", action_label)?;
    if let Ok(upsert) = request.get_bool("upsert") {
        options.upsert = Some(upsert);
    }
    let action = if multi {
        collection.update_many(filter, update)
    } else {
        collection.update_one(filter, update)
    };
    let result = action
        .with_options(options)
        .run()
        .map_err(CollectionActionError::Mongo)?;
    encode_update_action_result(&result, action_label).map_err(CollectionActionError::Message)
}

fn execute_delete_action(
    client: &MongoRustClient,
    database_name: &str,
    collection_name: &str,
    request: &Document,
    multi: bool,
) -> CollectionActionResult<Vec<u8>> {
    let action_label = if multi { "deleteMany" } else { "deleteOne" };
    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);
    let filter = request
        .get_document("filter")
        .map_err(|error| {
            CollectionActionError::Message(format!("{action_label} request missing filter: {error}"))
        })?
        .clone();

    let mut options = DeleteOptions::default();
    options.write_concern = read_write_concern(request, action_label)?;
    options.collation = read_collation(request, action_label)?;
    options.hint = read_hint(request);
    let action = if multi {
        collection.delete_many(filter)
    } else {
        collection.delete_one(filter)
    };
    let result = action
        .with_options(options)
        .run()
        .map_err(CollectionActionError::Mongo)?;
    encode_delete_action_result(&result, action_label).map_err(CollectionActionError::Message)
}

fn collection_action_error_response(error: &MongoError) -> Option<Vec<u8>> {
    error
        .server_response()
        .map(|response| response.as_bytes().to_vec())
}

fn read_write_concern(
    request: &Document,
    action_label: &str,
) -> CollectionActionResult<Option<WriteConcern>> {
    match request.get_document("writeConcern") {
        Ok(write_concern) => from_document::<WriteConcern>(write_concern.clone())
            .map(Some)
            .map_err(|error| {
                CollectionActionError::Message(format!(
                    "{action_label} writeConcern decode failed: {error}"
                ))
            }),
        Err(_) => Ok(None),
    }
}

fn read_collation(
    request: &Document,
    action_label: &str,
) -> CollectionActionResult<Option<Collation>> {
    match request.get_document("collation") {
        Ok(collation) => from_document::<Collation>(collation.clone())
            .map(Some)
            .map_err(|error| {
                CollectionActionError::Message(format!(
                    "{action_label} collation decode failed: {error}"
                ))
            }),
        Err(_) => Ok(None),
    }
}

fn read_hint(request: &Document) -> Option<Hint> {
    if let Ok(hint_name) = request.get_str("hint") {
        return Some(Hint::Name(hint_name.to_string()));
    }
    if let Ok(hint_document) = request.get_document("hintDocument") {
        return Some(Hint::Keys(hint_document.clone()));
    }
    request
        .get_document("hint")
        .ok()
        .map(|hint_document| Hint::Keys(hint_document.clone()))
}

fn read_document_array_field(
    request: &Document,
    key: &str,
    action_label: &str,
) -> CollectionActionResult<Vec<Document>> {
    let values = request.get_array(key).map_err(|error| {
        CollectionActionError::Message(format!(
            "{action_label} request missing {key}: {error}"
        ))
    })?;
    let mut documents = Vec::with_capacity(values.len());
    for value in values {
        match value {
            Bson::Document(document) => documents.push(document.clone()),
            _ => {
                return Err(CollectionActionError::Message(format!(
                    "{action_label} {key} entry was not a document"
                )))
            }
        }
    }
    Ok(documents)
}

fn read_document_array_field_optional(
    request: &Document,
    key: &str,
    action_label: &str,
) -> CollectionActionResult<Option<Vec<Document>>> {
    match request.get_array(key) {
        Ok(_) => read_document_array_field(request, key, action_label).map(Some),
        Err(_) => Ok(None),
    }
}

fn read_update_modifications(
    request: &Document,
    key: &str,
    action_label: &str,
) -> CollectionActionResult<UpdateModifications> {
    match request.get(key) {
        Some(Bson::Document(document)) => Ok(UpdateModifications::Document(document.clone())),
        Some(Bson::Array(values)) => {
            let mut pipeline = Vec::with_capacity(values.len());
            for value in values {
                match value {
                    Bson::Document(document) => pipeline.push(document.clone()),
                    _ => {
                        return Err(CollectionActionError::Message(format!(
                            "{action_label} {key} pipeline stage was not a document"
                        )))
                    }
                }
            }
            Ok(UpdateModifications::Pipeline(pipeline))
        }
        Some(_) => Err(CollectionActionError::Message(format!(
            "{action_label} {key} had an unsupported type"
        ))),
        None => Err(CollectionActionError::Message(format!(
            "{action_label} request missing {key}"
        ))),
    }
}

fn encode_insert_one_action_result(
    _result: &InsertOneResult,
) -> Result<Vec<u8>, String> {
    encode_success_document(
        Document::from_iter([("n".to_string(), Bson::Int32(1))]),
        "insertOne",
    )
}

fn encode_insert_many_action_result(result: &InsertManyResult) -> Result<Vec<u8>, String> {
    encode_success_document(
        Document::from_iter([("n".to_string(), bson_count(result.inserted_ids.len() as i64))]),
        "insertMany",
    )
}

fn encode_update_action_result(
    result: &UpdateResult,
    action_label: &str,
) -> Result<Vec<u8>, String> {
    let mut response = Document::from_iter([
        ("n".to_string(), bson_count(result.matched_count as i64)),
        ("nModified".to_string(), bson_count(result.modified_count as i64)),
    ]);
    if let Some(upserted_id) = result.upserted_id.clone() {
        response.insert(
            "upserted",
            Bson::Array(vec![Bson::Document(Document::from_iter([
                ("index".to_string(), Bson::Int32(0)),
                ("_id".to_string(), upserted_id),
            ]))]),
        );
    }
    encode_success_document(response, action_label)
}

fn encode_delete_action_result(result: &DeleteResult, action_label: &str) -> Result<Vec<u8>, String> {
    encode_success_document(
        Document::from_iter([("n".to_string(), bson_count(result.deleted_count as i64))]),
        action_label,
    )
}

fn encode_success_document(mut document: Document, label: &str) -> Result<Vec<u8>, String> {
    document.insert("ok", Bson::Double(1.0));
    to_vec(&document).map_err(|error| format!("{label} BSON encode failed: {error}"))
}

fn bson_count(value: i64) -> Bson {
    match i32::try_from(value) {
        Ok(value) => Bson::Int32(value),
        Err(_) => Bson::Int64(value),
    }
}

fn execute_find_documents(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<Vec<Document>, String> {
    open_find_cursor(client, database_name, request)?.collect_all()
}

fn open_find_cursor(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<MongoRustCursor, String> {
    let collection_name = request
        .get_str("find")
        .or_else(|_| request.get_str("collection"))
        .map_err(|error| format!("find request missing collection: {error}"))?;
    let operation_label = format!("find {collection_name}");
    let started_at = Instant::now();

    let filter = match request.get_document("filter") {
        Ok(document) => document.clone(),
        Err(_) => Document::new(),
    };
    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);

    let mut options = FindOptions::default();
    let mut ffi_batch_size = normalized_ffi_batch_size(read_command_batch_size(request));
    if let Ok(projection) = request.get_document("projection") {
        options.projection = Some(projection.clone());
    }
    if let Ok(sort) = request.get_document("sort") {
        options.sort = Some(sort.clone());
    }
    if let Ok(hint_name) = request.get_str("hint") {
        options.hint = Some(Hint::Name(hint_name.to_string()));
    } else if let Ok(hint_document) = request.get_document("hintDocument") {
        options.hint = Some(Hint::Keys(hint_document.clone()));
    } else if let Ok(hint_document) = request.get_document("hint") {
        options.hint = Some(Hint::Keys(hint_document.clone()));
    }
    if let Some(skip) = read_i64_value(request, "skip") {
        if skip > 0 {
            options.skip = Some(skip as u64);
        }
    }

    let batch_size = read_command_batch_size(request);
    if let Some(batch_size) = batch_size {
        options.batch_size = Some(batch_size as u32);
    }

    let single_batch = request.get_bool("singleBatch").unwrap_or(false);
    if let Some(limit) = read_i64_value(request, "limit") {
        if limit != 0 {
            options.limit = Some(if single_batch && limit > 0 { -limit } else { limit });
            if limit > 0 {
                ffi_batch_size = ffi_batch_size.min(limit as usize);
            }
        }
    } else if single_batch {
        if let Some(batch_size) = batch_size {
            options.limit = Some(-i64::from(batch_size));
        }
    }

    if let Some(max_time_ms) = read_i64_value(request, "maxTimeMS") {
        if max_time_ms > 0 {
            options.max_time = Some(Duration::from_millis(max_time_ms as u64));
        }
    }
    if let Some(comment) = request.get("comment") {
        options.comment = Some(comment.clone());
    }
    if let Ok(read_concern) = request.get_document("readConcern") {
        options.read_concern = Some(
            from_document::<ReadConcern>(read_concern.clone())
                .map_err(|error| format!("find readConcern decode failed: {error}"))?,
        );
    }
    if let Ok(max) = request.get_document("max") {
        options.max = Some(max.clone());
    }
    if let Ok(min) = request.get_document("min") {
        options.min = Some(min.clone());
    }
    if let Ok(return_key) = request.get_bool("returnKey") {
        options.return_key = Some(return_key);
    }
    if let Ok(show_record_id) = request.get_bool("showRecordId") {
        options.show_record_id = Some(show_record_id);
    }
    if let Ok(no_cursor_timeout) = request.get_bool("noCursorTimeout") {
        options.no_cursor_timeout = Some(no_cursor_timeout);
    }
    if let Ok(allow_partial_results) = request.get_bool("allowPartialResults") {
        options.allow_partial_results = Some(allow_partial_results);
    } else if let Ok(allow_partial_result) = request.get_bool("allowPartialResult") {
        options.allow_partial_results = Some(allow_partial_result);
    }
    if let Ok(allow_disk_use) = request.get_bool("allowDiskUse") {
        options.allow_disk_use = Some(allow_disk_use);
    }
    if let Ok(collation) = request.get_document("collation") {
        options.collation = Some(
            from_document::<Collation>(collation.clone())
                .map_err(|error| format!("find collation decode failed: {error}"))?,
        );
    }

    let cursor = collection
        .find(filter)
        .with_options(options)
        .run()
        .map_err(|error| format!("{operation_label} failed: {error}"))?;
    log_slow_operation(&operation_label, started_at);
    Ok(MongoRustCursor::new_document(cursor, ffi_batch_size, "find"))
}

fn execute_aggregate_documents(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<Vec<Document>, String> {
    open_aggregate_cursor(client, database_name, request)?.collect_all()
}

fn open_aggregate_cursor(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<MongoRustCursor, String> {
    let collection_name = request
        .get_str("aggregate")
        .or_else(|_| request.get_str("collection"))
        .map_err(|error| format!("aggregate request missing collection: {error}"))?;
    let operation_label = format!("aggregate {collection_name}");
    let started_at = Instant::now();
    let pipeline_values = request
        .get_array("pipeline")
        .map_err(|error| format!("aggregate request missing pipeline: {error}"))?;

    let mut pipeline = Vec::with_capacity(pipeline_values.len());
    for stage in pipeline_values {
        match stage {
            Bson::Document(document) => pipeline.push(document.clone()),
            _ => {
                return Err("aggregate pipeline stage was not a document".to_string());
            }
        }
    }

    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);

    let mut options = AggregateOptions::default();
    let ffi_batch_size = normalized_ffi_batch_size(read_command_batch_size(request));
    if let Ok(allow_disk_use) = request.get_bool("allowDiskUse") {
        options.allow_disk_use = Some(allow_disk_use);
    }
    if let Ok(cursor) = request.get_document("cursor") {
        if let Some(batch_size) = read_document_batch_size(cursor) {
            options.batch_size = Some(batch_size as u32);
        }
    }
    if let Some(max_time_ms) = read_i64_value(request, "maxTimeMS") {
        if max_time_ms > 0 {
            options.max_time = Some(Duration::from_millis(max_time_ms as u64));
        }
    }
    if let Ok(bypass_document_validation) = request.get_bool("bypassDocumentValidation") {
        options.bypass_document_validation = Some(bypass_document_validation);
    }
    if let Ok(read_concern) = request.get_document("readConcern") {
        options.read_concern = Some(
            from_document::<ReadConcern>(read_concern.clone())
                .map_err(|error| format!("aggregate readConcern decode failed: {error}"))?,
        );
    }
    if let Ok(collation) = request.get_document("collation") {
        options.collation = Some(
            from_document::<Collation>(collation.clone())
                .map_err(|error| format!("aggregate collation decode failed: {error}"))?,
        );
    }
    if let Some(comment) = request.get("comment") {
        options.comment = Some(comment.clone());
    }
    if let Ok(hint_name) = request.get_str("hint") {
        options.hint = Some(Hint::Name(hint_name.to_string()));
    } else if let Ok(hint_document) = request.get_document("hintDocument") {
        options.hint = Some(Hint::Keys(hint_document.clone()));
    } else if let Ok(hint_document) = request.get_document("hint") {
        options.hint = Some(Hint::Keys(hint_document.clone()));
    }
    if let Ok(let_vars) = request.get_document("let") {
        options.let_vars = Some(let_vars.clone());
    }

    let cursor = collection
        .aggregate(pipeline)
        .with_options(options)
        .run()
        .map_err(|error| format!("{operation_label} failed: {error}"))?;
    log_slow_operation(&operation_label, started_at);
    Ok(MongoRustCursor::new_document(cursor, ffi_batch_size, "aggregate"))
}

fn execute_list_collections_documents(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<Vec<Document>, String> {
    open_list_collections_cursor(client, database_name, request)?.collect_all()
}

fn open_list_collections_cursor(
    client: &MongoRustClient,
    database_name: &str,
    request: &Document,
) -> Result<MongoRustCursor, String> {
    let operation_label = "listCollections".to_string();
    let started_at = Instant::now();
    let ffi_batch_size = normalized_ffi_batch_size(read_command_batch_size(request));
    let database = client.client.database(database_name);
    let mut action = database.list_collections();
    if let Some(batch_size) = read_command_batch_size(request) {
        action = action.batch_size(batch_size as u32);
    }
    if let Ok(filter) = request.get_document("filter") {
        action = action.filter(filter.clone());
    }
    if let Some(comment) = request.get("comment") {
        action = action.comment(comment.clone());
    }
    if let Ok(authorized_collections) = request.get_bool("authorizedCollections") {
        action = action.authorized_collections(authorized_collections);
    }

    let cursor = action
        .run()
        .map_err(|error| format!("{operation_label} failed: {error}"))?;
    log_slow_operation(&operation_label, started_at);
    Ok(MongoRustCursor::new_collection_specifications(
        cursor,
        ffi_batch_size,
        "listCollections",
    ))
}

fn execute_list_indexes_documents(
    client: &MongoRustClient,
    database_name: &str,
    collection_name: &str,
    request: &Document,
) -> Result<Vec<Document>, String> {
    open_list_indexes_cursor(client, database_name, collection_name, request)?.collect_all()
}

fn open_list_indexes_cursor(
    client: &MongoRustClient,
    database_name: &str,
    collection_name: &str,
    request: &Document,
) -> Result<MongoRustCursor, String> {
    let operation_label = format!("listIndexes {collection_name}");
    let started_at = Instant::now();
    let ffi_batch_size = normalized_ffi_batch_size(read_command_batch_size(request));
    let collection = client
        .client
        .database(database_name)
        .collection::<Document>(collection_name);
    let mut action = collection.list_indexes();
    if let Some(batch_size) = read_command_batch_size(request) {
        action = action.batch_size(batch_size as u32);
    }
    if let Some(max_time_ms) = read_i64_value(request, "maxTimeMS") {
        if max_time_ms > 0 {
            action = action.max_time(Duration::from_millis(max_time_ms as u64));
        }
    }
    if let Some(comment) = request.get("comment") {
        action = action.comment(comment.clone());
    }

    let cursor = action
        .run()
        .map_err(|error| format!("{operation_label} failed: {error}"))?;
    log_slow_operation(&operation_label, started_at);
    Ok(MongoRustCursor::new_index_models(
        cursor,
        ffi_batch_size,
        "listIndexes",
    ))
}

fn collect_cursor_documents(
    client: &MongoRustClient,
    response: Document,
    batch_size: Option<i32>,
) -> Result<Vec<Document>, String> {
    let cursor = response
        .get_document("cursor")
        .map_err(|error| format!("cursor response missing cursor: {error}"))?;
    let mut documents = extract_cursor_batch(cursor)?;
    let mut cursor_id = read_cursor_id(cursor.get("id"))?;
    if cursor_id == 0 {
        return Ok(documents);
    }

    let namespace = cursor
        .get_str("ns")
        .map_err(|error| format!("cursor response missing ns: {error}"))?;
    let database_name = database_name_from_namespace(namespace)?;
    let collection_name = collection_name_from_namespace(namespace)?;

    while cursor_id != 0 {
        let mut get_more = Document::from_iter([
            ("getMore".to_string(), Bson::Int64(cursor_id)),
            (
                "collection".to_string(),
                Bson::String(collection_name.clone()),
            ),
        ]);
        if let Some(batch_size) = batch_size {
            if batch_size > 0 {
                get_more.insert("batchSize", Bson::Int32(batch_size));
            }
        }

        let response = client
            .client
            .database(&database_name)
            .run_command(get_more)
            .run()
            .map_err(|error| format!("getMore failed: {error}"))?;
        let cursor = response
            .get_document("cursor")
            .map_err(|error| format!("getMore response missing cursor: {error}"))?;
        documents.extend(extract_cursor_batch(cursor)?);
        cursor_id = read_cursor_id(cursor.get("id"))?;
    }

    Ok(documents)
}

fn extract_cursor_batch(cursor: &Document) -> Result<Vec<Document>, String> {
    let batch = if let Ok(batch) = cursor.get_array("firstBatch") {
        batch
    } else if let Ok(batch) = cursor.get_array("nextBatch") {
        batch
    } else {
        return Ok(Vec::new());
    };

    let mut documents = Vec::with_capacity(batch.len());
    for value in batch {
        match value {
            Bson::Document(document) => documents.push(document.clone()),
            _ => return Err("cursor batch contained a non-document value".to_string()),
        }
    }
    Ok(documents)
}

fn read_cursor_id(value: Option<&Bson>) -> Result<i64, String> {
    match value {
        Some(Bson::Int64(value)) => Ok(*value),
        Some(Bson::Int32(value)) => Ok(i64::from(*value)),
        Some(Bson::Null) => Ok(0),
        Some(value) => Err(format!("cursor id had unexpected type: {value:?}")),
        None => Err("cursor response missing id".to_string()),
    }
}

fn read_command_batch_size(command: &Document) -> Option<i32> {
    if let Some(batch_size) = read_document_batch_size(command) {
        return Some(batch_size);
    }
    command
        .get_document("cursor")
        .ok()
        .and_then(read_document_batch_size)
}

fn read_document_batch_size(document: &Document) -> Option<i32> {
    if let Ok(batch_size) = document.get_i32("batchSize") {
        if batch_size > 0 {
            return Some(batch_size);
        }
    }
    if let Ok(batch_size) = document.get_i64("batchSize") {
        if batch_size > 0 && batch_size <= i64::from(i32::MAX) {
            return Some(batch_size as i32);
        }
    }
    None
}

fn read_i64_value(document: &Document, key: &str) -> Option<i64> {
    if let Ok(value) = document.get_i64(key) {
        return Some(value);
    }
    if let Ok(value) = document.get_i32(key) {
        return Some(i64::from(value));
    }
    None
}

fn normalized_ffi_batch_size(batch_size: Option<i32>) -> usize {
    batch_size
        .filter(|batch_size| *batch_size > 0)
        .map(|batch_size| batch_size as usize)
        .unwrap_or(DEFAULT_FFI_CURSOR_BATCH_SIZE)
}

fn collection_name_from_namespace(namespace: &str) -> Result<String, String> {
    namespace
        .split_once('.')
        .map(|(_, collection_name)| collection_name.to_string())
        .ok_or_else(|| format!("could not parse collection name from namespace {namespace}"))
}

fn describe_command(request: &Document) -> String {
    for key in [
        "find",
        "aggregate",
        "findAndModify",
        "count",
        "distinct",
        "listCollections",
        "listIndexes",
        "createIndexes",
        "listSearchIndexes",
        "createSearchIndexes",
        "updateSearchIndex",
        "dropSearchIndex",
        "insert",
        "update",
        "delete",
        "create",
        "drop",
        "collMod",
        "buildInfo",
        "hello",
        "ismaster",
        "ping",
    ] {
        if let Some(description) = describe_named_command(request, key) {
            return description;
        }
    }
    request
        .iter()
        .next()
        .map(|(key, value)| match value {
            Bson::String(target) if !target.is_empty() => format!("{key} {target}"),
            _ => key.to_string(),
        })
        .unwrap_or_else(|| "unknownCommand".to_string())
}

fn describe_named_command(request: &Document, key: &str) -> Option<String> {
    let value = request.get(key)?;
    Some(match value {
        Bson::String(target) if !target.is_empty() => format!("{key} {target}"),
        _ => key.to_string(),
    })
}

fn database_name_from_namespace(namespace: &str) -> Result<String, String> {
    namespace
        .split_once('.')
        .map(|(database_name, _)| database_name.to_string())
        .ok_or_else(|| format!("could not parse database name from namespace {namespace}"))
}

fn request_database_name(
    client: &MongoRustClient,
    request: &mut Document,
) -> Result<String, String> {
    match request.remove("$db") {
        Some(Bson::String(database_name)) if !database_name.is_empty() => Ok(database_name),
        Some(Bson::String(_)) | Some(Bson::Null) | None => Ok(client.database_name.clone()),
        Some(value) => Err(format!("command $db had unexpected type: {value:?}")),
    }
}

fn encode_document_list(documents: Vec<Document>, label: &str) -> Result<Vec<u8>, String> {
    to_vec(&Document::from_iter([(
        "documents".to_string(),
        Bson::Array(documents.into_iter().map(Bson::Document).collect()),
    )]))
    .map_err(|error| format!("{label} BSON encode failed: {error}"))
}

fn encode_cursor_response(
    database_name: &str,
    collection_name: &str,
    documents: Vec<Document>,
) -> Result<Vec<u8>, String> {
    let response = Document::from_iter([
        (
            "cursor".to_string(),
            Bson::Document(Document::from_iter([
                ("id".to_string(), Bson::Int64(0)),
                (
                    "ns".to_string(),
                    Bson::String(format!("{database_name}.{collection_name}")),
                ),
                (
                    "firstBatch".to_string(),
                    Bson::Array(documents.into_iter().map(Bson::Document).collect()),
                ),
            ])),
        ),
        ("ok".to_string(), Bson::Double(1.0)),
    ]);
    to_vec(&response).map_err(|error| format!("BSON encode failed: {error}"))
}

fn encode_search_index_cursor_response(
    database_name: &str,
    collection_name: &str,
    documents: Vec<Document>,
) -> Result<Vec<u8>, String> {
    encode_cursor_response(database_name, collection_name, documents)
}

fn encode_create_search_indexes_response(created_names: Vec<String>) -> Result<Vec<u8>, String> {
    let response = Document::from_iter([
        (
            "indexesCreated".to_string(),
            Bson::Array(
                created_names
                    .into_iter()
                    .map(|name| {
                        Bson::Document(Document::from_iter([
                            ("id".to_string(), Bson::String(name.clone())),
                            ("name".to_string(), Bson::String(name)),
                        ]))
                    })
                    .collect(),
            ),
        ),
        ("ok".to_string(), Bson::Double(1.0)),
    ]);
    to_vec(&response).map_err(|error| format!("BSON encode failed: {error}"))
}

fn encode_ok_response() -> Vec<u8> {
    to_vec(&Document::from_iter([("ok".to_string(), Bson::Double(1.0))]))
        .expect("encoding ok response should not fail")
}

fn read_c_string(value: *const c_char, field_name: &str) -> Result<String, String> {
    if value.is_null() {
        return Err(format!("{field_name} was null"));
    }
    unsafe { CStr::from_ptr(value) }
        .to_str()
        .map(|value| value.to_owned())
        .map_err(|_| format!("{field_name} was not valid UTF-8"))
}

fn read_bson_document(
    bytes: *const c_uchar,
    length: i32,
    field_name: &str,
) -> Result<Document, String> {
    if bytes.is_null() {
        return Err(format!("{field_name} bytes were null"));
    }
    if length <= 0 {
        return Err(format!("{field_name} length was invalid"));
    }
    let bytes = unsafe { std::slice::from_raw_parts(bytes, length as usize) };
    from_slice::<Document>(bytes)
        .map_err(|error| format!("{field_name} BSON decode failed: {error}"))
}

fn client_ref(client: *mut MongoRustClient) -> Result<&'static MongoRustClient, String> {
    if client.is_null() {
        return Err("Rust client handle was null".to_string());
    }
    Ok(unsafe { &*client })
}

fn cursor_ref_mut(cursor: *mut MongoRustCursor) -> Result<&'static mut MongoRustCursor, String> {
    if cursor.is_null() {
        return Err("Rust cursor handle was null".to_string());
    }
    Ok(unsafe { &mut *cursor })
}

fn write_bytes_result(
    result_bytes_out: *mut *mut c_uchar,
    result_len_out: *mut i32,
    bytes: Vec<u8>,
) {
    let mut bytes = bytes;
    let len = bytes.len() as i32;
    let ptr = bytes.as_mut_ptr();
    std::mem::forget(bytes);
    unsafe {
        if !result_bytes_out.is_null() {
            *result_bytes_out = ptr;
        }
        if !result_len_out.is_null() {
            *result_len_out = len;
        }
    }
}

fn write_error(error_out: *mut *mut c_char, message: &str) {
    log_rust_error(message);
    if error_out.is_null() {
        return;
    }
    let sanitized = message.replace('\0', " ");
    let message =
        CString::new(sanitized).unwrap_or_else(|_| CString::new("Rust backend error").unwrap());
    unsafe {
        *error_out = message.into_raw();
    }
}

fn log_slow_operation(label: &str, started_at: Instant) {
    log_slow_operation_with_level(label, started_at, SlowLogLevel::Warn);
}

fn log_slow_operation_with_level(
    label: &str,
    started_at: Instant,
    slow_log_level: SlowLogLevel,
) {
    let elapsed = started_at.elapsed();
    if elapsed >= SLOW_OPERATION_LOG_THRESHOLD {
        match slow_log_level {
            SlowLogLevel::Warn => {
                log_rust_warn(&format!("{label} took {}ms", elapsed.as_millis()))
            }
            SlowLogLevel::Info => {
                log_rust_info(&format!("{label} took {}ms", elapsed.as_millis()))
            }
            SlowLogLevel::Off => {}
        }
    }
}

fn log_rust_info(message: &str) {
    println!("[mongo_document_db_driver_rust][db] {message}");
}

fn log_rust_warn(message: &str) {
    eprintln!("[mongo_document_db_driver_rust][db][warn] {message}");
}

fn log_rust_error(message: &str) {
    eprintln!("[mongo_document_db_driver_rust][db][error] {message}");
}
