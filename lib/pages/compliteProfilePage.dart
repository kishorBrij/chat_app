

import 'dart:developer';
import 'dart:io';
import 'package:chat_app/model/uiHelper.dart';
import 'package:chat_app/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../model/userModel.dart';

class CompliteProfilePage extends StatefulWidget {

  final UserModel? userModel;
  final User? firebaseUser;

  const CompliteProfilePage({super.key, this.userModel, this.firebaseUser});

  @override
  State<CompliteProfilePage> createState() => _CompliteProfilePageState();
}

class _CompliteProfilePageState extends State<CompliteProfilePage> {

  TextEditingController fullNameController = TextEditingController();

 File? imageFile;

 /// for Select Image

  void selectImage(ImageSource source)async{
   XFile? pickedFile = await ImagePicker().pickImage(source: source);
   cropImage(pickedFile!);
  }

  /// For cropped Image

  void cropImage(XFile file)async{
  final croppedImage = await ImageCropper().cropImage(
      sourcePath: file.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressQuality: 20
  ).then((value) {

     log("message1111${value!.path}");

    setState(() {
      imageFile = File(value.path)  ;
    });
    log("message111$imageFile");
  });

  }

  /// For Photo Option

  void showPhotoOption(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        title: const Text("Upload profile picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              onTap: (){

                selectImage(ImageSource.gallery);

                Navigator.pop(context);
              },
              leading: const Icon(Icons.photo),
              title: const Text("Select from gallery"),
            ),

            ListTile(
              onTap: (){
               Navigator.pop(context);
                selectImage(ImageSource.camera);
              },
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
            ),
          ],
        ),
      );
    });
  }

  void checkValue (){
    String fullName = fullNameController.text.trim();


    if(fullName == "" || imageFile == ""){

      UiHelper.showAlertDialog(context, "Incomplete Data",
          "Please fill all the field and upload profile picture");
    }
    else{
      uploadData();
    }
  }

  /// For Upload Data

  void uploadData ()async{
    UiHelper.showLoadingDialog(context, "Uploading image");

    UploadTask uploadTask = FirebaseStorage.instance.ref("Location 1").
    child(widget.userModel!.uid.toString()).putFile(imageFile!);

    TaskSnapshot snapshot = await uploadTask;

    String? imgurl = await snapshot.ref.getDownloadURL();
    String? fullname = fullNameController.text.trim();

    widget.userModel!.fullname = fullname;
    widget.userModel!.profilepic = imgurl;

    await FirebaseFirestore.instance.collection("users").doc(
      widget.userModel!.uid).set(widget.userModel!.toMap()).then((value){
        log("Data uploaded!");

        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) =>
                HomePageScreen(userModel: widget.userModel!,
                    firebaseUser: widget.firebaseUser!))
        );
    });

  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Complete Profile '),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child: ListView(
            children: [

              const SizedBox(height: 20,),

              CupertinoButton(
                onPressed: (){
                  showPhotoOption();
                },
                padding: const EdgeInsets.all(0),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: (imageFile?.path != null) ? FileImage(imageFile!) : null,
                  child: (imageFile == null) ? const Icon(Icons.person, size: 60,) : null,
                ),
              ),

              const SizedBox(height: 20,),

              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name"
                ),
              ),

              const SizedBox(height: 20,),

              CupertinoButton(
                  color: Colors.deepPurple,
                  onPressed:(){
                    checkValue();

                  },
                  child: const Text("Submit")
              ),
            ],
          ),
        ),
      ),
    );
  }
}
