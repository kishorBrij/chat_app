import 'dart:developer';

import 'package:chat_app/model/chatRoomModel.dart';
import 'package:chat_app/model/firebaseHelper.dart';
import 'package:chat_app/model/uiHelper.dart';
import 'package:chat_app/model/userModel.dart';
import 'package:chat_app/pages/chartRoomPage.dart';
import 'package:chat_app/pages/loginPage.dart';
import 'package:chat_app/pages/searchPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePageScreen extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const HomePageScreen(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("Chat App"),
        actions: [
          IconButton(
              onPressed: ()async{
                await FirebaseAuth.instance.signOut();


                Navigator.popUntil(context, (route) => route.isFirst);

                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const LoginPage())
                );
              },
              icon:const Icon(Icons.exit_to_app)
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("chatrooms").
          where("participants.${widget.userModel.uid}",isEqualTo: true).snapshots(),
          builder: (context, snapshots){

            if(snapshots.connectionState == ConnectionState.active){
              if(snapshots.hasData){
                QuerySnapshot chatRoomSnapshots = snapshots.data as QuerySnapshot;

                return ListView.builder(
                    itemCount: chatRoomSnapshots.docs.length,
                    itemBuilder: (context, index){
                      ChatRoomModel chatRoomModel = ChatRoomModel.fromMap
                        (chatRoomSnapshots.docs[index].data() as Map<
                      String, dynamic>);

                      Map<String, dynamic> participants = chatRoomModel.participants!;

                      List<String> participantKeys  = participants.keys.toList();

                      participantKeys.remove(widget.userModel.uid);

                      return FutureBuilder(
                          future: FirebaseHelper.getUserModelById(participantKeys[0]),
                          builder: (context, userData){
                            if(userData.connectionState == ConnectionState.done){
                              if(userData.data != null){

                                UserModel targetUser = userData.data as UserModel;

                                return ListTile(
                                  onTap: (){
                                    Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => ChatRoomPage(
                                        targetUser: targetUser,
                                        chatroom: chatRoomModel,
                                        userModel: widget.userModel,
                                        firebaseUser: widget.firebaseUser)
                                    )
                                    );
                                  },
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(targetUser.profilepic.toString()),
                                  ),
                                  title: Text(targetUser.fullname.toString()),
                                  subtitle:(chatRoomModel.lastMessage.toString() != "") ?
                                  Text(chatRoomModel.lastMessage.toString()) :
                                  const Text("Say hi to your friend",style: TextStyle(color: Colors.blue),),
                                );
                              }
                             else{
                               return Container();
                              }

                            }
                            else{
                              return Container();
                            }

                          }
                      );
                    }
                );
              }
              else if(snapshots.hasError){
                return Center(
                  child: Text(snapshots.error.toString()),
                );

              }
              else{
                return const Center(
                  child: Text("No Chats"),
                );
              }
            }
            else{
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          Navigator.push(context,
          MaterialPageRoute(builder: (context) =>
              SearchPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser))
          );
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}
