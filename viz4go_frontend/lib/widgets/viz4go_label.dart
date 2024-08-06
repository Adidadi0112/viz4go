import 'package:flutter/material.dart';

class Viz4goLabel extends StatelessWidget {
  const Viz4goLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
                  child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'viz',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '4',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text: 'go',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              
                            ),
                          ),
                          const Text("description description description description description description description description description", style: TextStyle(fontSize: 20, color: Colors.white)),
                        ],
                      ),
                    ),
                );
  }
}