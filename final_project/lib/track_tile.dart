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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5, // Match elevation with your other cards
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            track['image'][1]['#text'].isEmpty ? 'http://mcgodftw.dev/i/r2kyqb6k.png' : track['image'][1]['#text'],
            width: 50,
            height: 50,
            fit: BoxFit.cover, // Ensures the image covers the area properly
            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
          ),
        ),
        title: Text(
          track['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track['artist']['#text'],
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            Text(
              scrobbledTime,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.more_vert, color: Colors.black54),
      ),
    );
  }
}



