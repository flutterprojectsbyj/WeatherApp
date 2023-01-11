/*
 * Copyright (C) 2021 - JMPFBMX
 */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Weather.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
      ),
      home: const MyApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool gpsStatus = false;
  bool hasPermission = true;
  late LocationPermission permission;
  late Position position;
  String long = "", lat = "";
  String deniedPermission = "";
  String gpsDisable = "";
  late StreamSubscription<Position> positionStream;
  late List<Placemark> placeMarks;
  String placeName = "";
  String domain="";
  String date1 = "";
  double temp1 = 0;
  String date2 = "";
  double temp2 = 0;

  @override
  void initState() {
    checkGps();
    super.initState();
  }

  checkGps() async {
    gpsStatus = await Geolocator.isLocationServiceEnabled();

    if (gpsStatus) {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        hasPermission = false;
        if (permission == LocationPermission.denied) {
          deniedPermission = "Location permissions are denied";
          hasPermission = false;
        } else if (permission == LocationPermission.deniedForever) {
          deniedPermission = "Location permissions are permanently denied";
          hasPermission = false;
        }
      }

      if (hasPermission) {
        setState(() {});
        getLocation();
      }
    } else {
      gpsDisable = "GPS Service is not enabled, turn on GPS location";
    }

    setState(() {});
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    lat = position.latitude.toString();
    long = position.longitude.toString();
    placeMarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    placeName = "${placeMarks.first.administrativeArea}, ${placeMarks.first.street}";
    domain = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$long&daily=temperature_2m_max&timezone=${DateTime.now().timeZoneName}";
    var client = http.Client();
    var url = Uri.parse(domain);
    var response = await client.get(url);
    if (response.statusCode == 200) {
      Map body = jsonDecode(response.body);
      print(body);
      Map<String, dynamic> data = body["daily"];
      final a = Daily.fromJson(data);
      date1 = a.time!.elementAt(0);
      temp1 = a.temperature2mMax!.elementAt(0);
      date2 = a.time!.elementAt(1);
      temp2 = a.temperature2mMax!.elementAt(1);
      print(data);
    } else {
      print(response.statusCode);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather App"),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Visibility(visible: !gpsStatus, child: Text(gpsDisable)),
                  Visibility(visible: !hasPermission, child: Text(deniedPermission)),
                  Text("Location: \n$placeName", style: const TextStyle(fontSize: 20), textAlign: TextAlign.center,),
                ]
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Text("Date: $date1\nTemp: $temp1ºC"),
                  Text("$date1", style: const TextStyle(fontSize: 20)),
                  Text("$temp1ºC", style: const TextStyle(fontSize: 50))
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("$date2", style: const TextStyle(fontSize: 20)),
                  Text("$temp2ºC", style: const TextStyle(fontSize: 50))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}