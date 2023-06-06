import 'dart:developer';

import 'package:chat_app/main.dart';
import 'package:chat_app/model/chatRoomModel.dart';
import 'package:chat_app/model/messageModel.dart';
import 'package:chat_app/model/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {


  final UserModel targetUser;
  final ChatRoomModel chatroom;
  final UserModel userModel;
  final User firebaseUser;

  const ChatRoomPage({super.key, required this.targetUser, required this.chatroom, required this.userModel, required this.firebaseUser});


  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {

  TextEditingController messageController = TextEditingController();

  void sendMessage()async{
    String msg = messageController.text.trim();
    messageController.clear();

    if(msg != ""){
      //send Message
      MessageModel newMessage = MessageModel(
        messageId: uuid.v1(),
        sender: widget.userModel.uid,
        createdon: DateTime.now(),
        text: msg,
        seen: false
      );

      FirebaseFirestore.instance.collection("chatrooms").doc(
        widget.chatroom.chatroomId).collection("message").doc(
        newMessage.messageId).set(newMessage.toMap());

      widget.chatroom.lastMessage = msg;
      FirebaseFirestore.instance.collection("chatrooms").doc(widget
      .chatroom.chatroomId).set(widget.chatroom.toMap());

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [

            CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(widget.targetUser.profilepic.toString())
            ),

            const SizedBox(width: 10,),

            Text(widget.targetUser.fullname.toString()),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [

            // This is where the chat will go
            Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection("chatrooms").
                    doc(widget.chatroom.chatroomId).collection("message").
                   orderBy("createdon", descending: true).snapshots(),
                    builder: (context, snapshot){

                      //log("message${snapshot.data!.docs.first.id}");
                      if(snapshot.connectionState == ConnectionState.active){

                        if(snapshot.hasData){
                          QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                          return ListView.builder(
                            reverse: true,
                            itemCount: dataSnapshot.docs.length,
                            itemBuilder: (context, index){
                              MessageModel currentMessage = MessageModel.fromMap(
                                dataSnapshot.docs[index].data() as Map<String, dynamic>
                              );

                              return Row(
                                mainAxisAlignment: (currentMessage.sender ==
                                widget.userModel.uid) ?
                                MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 3
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                                    decoration: BoxDecoration(
                                      color:(currentMessage.sender == widget.userModel.uid)
                                        ? Colors.grey :Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(5)
                                    ),
                                      child: Text(currentMessage.text.toString(),
                                      style: const TextStyle(color: Colors.white),
                                      )),
                                ],
                              );
                            },
                          );

                        }else if(snapshot.hasError){
                          return const Center(
                            child: Text("Connection error"),
                          );
                        }else{
                          return const Center(
                            child: Text("say hii to your friend"),
                          );
                        }
                      }else{
                         return const Center(child: CircularProgressIndicator(),);
                      }
                    },
                  ),
                ),
            ),

            Container(
              color: Colors.grey[300],
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 5
              ),
              child: Row(
                children: [

                  Flexible(
                      child: TextField(
                        controller: messageController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Enter message"
                        ),
                      ),
                  ),

                  IconButton(
                      onPressed: (){
                        sendMessage();
                      },
                      icon: const Icon(Icons.send),color: Colors.blue,

                  )
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
