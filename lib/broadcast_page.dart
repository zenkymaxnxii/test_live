import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/appid.dart';

class BroadCastPage extends StatefulWidget {
  const BroadCastPage(
      {super.key, required this.channelName, required this.isBroadCaster});
  final String channelName;
  final bool isBroadCaster;

  @override
  State<BroadCastPage> createState() => _BroadCastPageState();
}

class _BroadCastPageState extends State<BroadCastPage> {
  final _users = <int>[];
  late RtcEngine _engine;
  bool muted = false;
  int? streamId;
  bool joinChannel = false;
  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk and leave channel
    // _engine.destroy();
    _engine.leaveChannel(
        options: const LeaveChannelOptions(
            stopAllEffect: true,
            stopAudioMixing: true,
            stopMicrophoneRecording: true));
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    if (mounted) initAgora();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("local user ${connection.localUid} joined");
        setState(() {
          joinChannel = true;
        });
      },
      onLeaveChannel: (connection, stats) {
        setState(() {
          _users.clear();
          joinChannel = false;
        });
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("remote user $remoteUid joined");
        setState(() {
          setState(() {
            _users.add(remoteUid);
          });
        });
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        debugPrint("remote user $remoteUid left channel");
        setState(() {
          _users.remove(remoteUid);
        });
      },
      onStreamMessage: (connection, remoteUid, streamId, data, length, sentTs) {
        final String info = "here is the message ${data.first.toString()}";
        if (kDebugMode) {
          print(info);
        }
      },
      onStreamMessageError:
          (connection, remoteUid, streamId, code, missed, cached) {
        final String info = "here is the error $code";
        if (kDebugMode) {
          print(info);
        }
      },
      onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
        debugPrint(
            '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
      },
    ));
    if (widget.isBroadCaster) {
      streamId = await _engine.createDataStream(
          const DataStreamConfig(ordered: false, syncWithAudio: false));
    }
    await _engine.enableVideo();
    if (widget.isBroadCaster) {
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: joinChannel
            ? Stack(
                children: <Widget>[
                  _broadcastView(),
                  _toolbar(),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  Widget _toolbar() {
    return widget.isBroadCaster
        ? Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RawMaterialButton(
                  onPressed: _onToggleMute,
                  // ignore: sort_child_properties_last
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
                RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.redAccent,
                  padding: const EdgeInsets.all(15.0),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 35.0,
                  ),
                ),
                RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  // ignore: sort_child_properties_last
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
              ],
            ),
          )
        : Container();
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.isBroadCaster) {
      list.add(AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      ));
    }
    for (var uid in _users) {
      list.add(AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      ));
    }
    return list;
  }

  /// Video view row wrapper
  Widget _expandedVideoView(List<Widget> views) {
    final wrappedViews = views
        .map<Widget>((view) => Expanded(child: Container(child: view)))
        .toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _broadcastView() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Column(
          children: <Widget>[
            _expandedVideoView([views[0]])
          ],
        );
      case 2:
        return Column(
          children: <Widget>[
            _expandedVideoView([views[0]]),
            _expandedVideoView([views[1]])
          ],
        );
      case 3:
        return Column(
          children: <Widget>[
            _expandedVideoView(views.sublist(0, 2)),
            _expandedVideoView(views.sublist(2, 3))
          ],
        );
      case 4:
        return Column(
          children: <Widget>[
            _expandedVideoView(views.sublist(0, 2)),
            _expandedVideoView(views.sublist(2, 4))
          ],
        );
      default:
    }
    return Container();
  }

  void _onCallEnd(BuildContext context) {
    _engine.leaveChannel(options: const LeaveChannelOptions());
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    if (streamId != null) {}
    // _engine.sendStreamMessage(data: ,streamId: streamId,length: ));
    _engine.switchCamera();
  }
}
