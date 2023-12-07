import 'package:flutter/material.dart';
import '../utils/fetch_image.dart';

class TrackTile extends StatelessWidget {
  final String trackName;
  final String artistName;

  TrackTile({
    required this.trackName,
    required this.artistName,
  });

  Future<String> _getImageUrl() async {
    return await fetchTrackImageUrl(artistName, trackName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getImageUrl(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        String displayImageUrl = snapshot.hasData ? snapshot.data! : 'http://mcgodftw.dev/i/r2kyqb6k.png';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                displayImageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
              ),
            ),
            title: Text(
              trackName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artistName),
              ],
            ),
          ),
        );
      },
    );
  }
}
