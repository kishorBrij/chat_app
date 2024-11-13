
import 'package:chat_app/main.dart';
import 'package:chat_app/model/chatRoomModel.dart';
import 'package:chat_app/model/userModel.dart';
import 'package:chat_app/pages/chartRoomPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const SearchPage(
      {super.key, required this.userModel, required this.firebaseUser});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  TextEditingController searchController = TextEditingController();

  Future<ChatRoomModel?> getChatroomModel(UserModel targetUser)async{
    ChatRoomModel? chartRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection
      ("chatrooms").where("participants.${widget.userModel.uid}",isEqualTo: true).
    where("participants.${targetUser.uid}",isEqualTo: true).get();

    if(snapshot.docs.isNotEmpty){
      // Fetch the existing one
      
     var docData = snapshot.docs[0].data();
     ChatRoomModel existingChartroom = ChatRoomModel.fromMap(
       docData as Map<String, dynamic>
     );

     chartRoom = existingChartroom;
    }
    else{
      // Create a new one
      ChatRoomModel newChartroom = ChatRoomModel(
        chatroomId: uuid.v1(),
        lastMessage: "",
        participants: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString():true,
        }
      );

      await FirebaseFirestore.instance.collection("chatrooms").doc(
        newChartroom.chatroomId).set(newChartroom.toMap());

      chartRoom = newChartroom;

     print("new chartroom created!");
    }
    return chartRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Search"),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(labelText: "Email Address"),
              ),
              const SizedBox(
                height: 20,
              ),
              CupertinoButton(
                onPressed: () {
                  setState(() {});

                },
                color: Colors.blue,
                child: const Text("Search"),
              ),
              const SizedBox(
                height: 20,
              ),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where("email", isEqualTo: searchController.text)
                    .where("email", isNotEqualTo: widget.userModel.email)
                    .snapshots(),
                builder: (context, snapshots) {
                  if (snapshots.connectionState == ConnectionState.active) {
                    if (snapshots.hasData) {
                      QuerySnapshot dataSnapshot =
                          snapshots.data as QuerySnapshot;

                      if (dataSnapshot.docs.isNotEmpty) {
                        Map<String, dynamic> userMap =
                            dataSnapshot.docs[0].data() as Map<String, dynamic>;

                        UserModel searchUser = UserModel.fromMap(userMap);

                        return ListTile(
                          onTap: ()async {

                            ChatRoomModel? chartroomModel = await
                                getChatroomModel(searchUser);

                            if(chartroomModel != null){
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                           ChatRoomPage(
                                            targetUser: searchUser,
                                            userModel: widget.userModel,
                                             firebaseUser: widget.firebaseUser,
                                             chatroom: chartroomModel ,
                                          )));
                            }

                          },
                          leading: CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                NetworkImage(searchUser.profilepic!),
                          ),
                          title: Text(searchUser.fullname!),
                          subtitle: Text(searchUser.email!),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                        );
                      } else {
                        return const Text("No Result Founded!");
                      }
                    } else if (snapshots.hasError) {
                      return const Text("Error occurred!");
                    } else {
                      return const Text("No Result Founded!");
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
