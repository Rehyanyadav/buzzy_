import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final _audioRecorder = AudioRecorder();

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        return await _audioRecorder.stop();
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
