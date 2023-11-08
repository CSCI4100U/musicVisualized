import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrackListTile extends StatelessWidget {
  final Map<String, dynamic> track;

  TrackListTile({required this.track});

  String _formatScrobbledTime(dynamic dateData) {
    if (dateData == null) {
      return 'Scrobbling now';
    } else {
      final scrobbleDate = DateTime.fromMillisecondsSinceEpoch(int.parse(dateData['uts']) * 1000);
      final currentDate = DateTime.now();
      final difference = currentDate.difference(scrobbleDate);

      if (difference.inDays >= 1) {
        return DateFormat('d MMM h:mma').format(scrobbleDate);
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final scrobbledTime = _formatScrobbledTime(track['date']);

    return Card(
      elevation: 2,
      margin: EdgeInsets.all(8),
      child: ListTile(
        leading: Image.network(
          track['image'][1]['#text'].isEmpty ? 'http://mcgodftw.dev/i/r2kyqb6k.png' : track['image'][1]['#text'],
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) {
            return Image.network('http://mcgodftw.dev/i/r2kyqb6k.png');
          },
        ),
        title: Text(
          track['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track['artist']['#text']),
            Text(scrobbledTime),
          ],
        ),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }
}
