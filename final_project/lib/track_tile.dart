import 'package:flutter/material.dart';

class TrackListTile extends StatelessWidget {
  final Map<String, dynamic> track;

  TrackListTile({required this.track});

  @override
  Widget build(BuildContext context) {
    var scrobbledTime = track['date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(track['date']['uts']) * 1000).toString()
        : 'Time not available';

    return Card(
      elevation: 2,
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: Image.network(
          track['image'][1]['#text'],
          width: 50,
          height: 50,
        ),
        title: Text(
          track['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track['artist']['#text']),
            Text('Scrobbled at: $scrobbledTime'),
          ],
        ),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }
}
