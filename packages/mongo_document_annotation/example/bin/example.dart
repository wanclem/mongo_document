import 'package:example/env/dump.dart';
import 'package:example/models/user.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  Environment env = Environment();
  String mongoUri = env.get('MONGO_URI') ?? "";
  await MongoConnection.init(mongoUri);
  //Creat a new user
  User? newUser = await User(firstName: "Wan", lastName: "Clem").save();
  print("User Created: ${newUser?.toJson()}");
  //Find a user by id
  User? user = await Users.findById(newUser?.id);
  //Print the user
  print("User Found: ${user?.toJson()}");
  //Update the user
  newUser = await newUser?.copyWith(firstName: "John").save();
  //Print the user
  print("User Updated: ${newUser?.toJson()}");
  //DSL find One
  user = await Users.findOne((p) => p.firstName.eq("John"));
  //Print the user
  print("User Found: ${user?.toJson()}");
  
}
