import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'flutter_sound_player_platform_interface.dart';
import 'flutter_sound_platform_interface.dart';

const MethodChannel _channel = MethodChannel('com.dooboolab.flutter_sound_player');

/// An implementation of [FlutterSoundPlayerPlatform] that uses method channels.
class MethodChannelFlutterSoundPlayer extends FlutterSoundPlayerPlatform
{
  List<FlutterSoundPlayerCallback> _slots = [];
  Completer<bool> openAudioSessionCompleter;
  Completer<Map> startPlayerCompleter;



  /* ctor */ MethodChannelFlutterSoundPlayer()
  {
    setCallback();
  }

  void setCallback()
  {
    //_channel = const MethodChannel('com.dooboolab.flutter_sound_player');
    _channel.setMethodCallHandler((MethodCall call)
    {
      return channelMethodCallHandler(call);
    });
  }



  Future<dynamic> channelMethodCallHandler(MethodCall call)
  {
    FlutterSoundPlayerCallback aPlayer = _slots[call.arguments['slotNo'] as int];
    Map arg = call.arguments ;

    switch (call.method)
    {
      case "updateProgress":
        {
          aPlayer.updateProgress(duration: Duration(milliseconds: arg['duration']), position: Duration(milliseconds: arg['position']));
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.audioPlayerFinished(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'pause': // Pause/Resume
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.pause(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'skipForward':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.skipForward(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'skipBackward':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.skipBackward(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'updatePlaybackState':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.updatePlaybackState(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'openAudioSessionCompleted':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          bool success = arg['arg'] as bool;
          openAudioSessionCompleter.complete(success );
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'startPlayerCompleted':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          //int duration =  arg['duration'] as int;
          //Duration d = Duration(milliseconds: duration);
          startPlayerCompleter.complete(arg ) ;
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'needSomeFood':
        {
          aPlayer.needSomeFood(arg['arg']);
        }
        break;


      default:
        throw ArgumentError('Unknown method ${call.method}');
    }

    return null;
  }


//===============================================================================================================================


  int findSession(FlutterSoundPlayerCallback aSession)
  {
    for (var i = 0; i < _slots.length; ++i)
    {
      if (_slots[i] == aSession)
      {
        return i;
      }
    }
    return -1;
  }

  @override
  void openSession(FlutterSoundPlayerCallback aSession)
  {
    assert(findSession(aSession) == -1);

    for (var i = 0; i < _slots.length; ++i)
    {
      if (_slots[i] == null)
      {
        _slots[i] = aSession;
        return;
      }
    }
    _slots.add(aSession);
  }

  @override
  void closeSession(FlutterSoundPlayerCallback aSession)
  {
    _slots[findSession(aSession)] = null;
  }


  Future<int> invokeMethod (FlutterSoundPlayerCallback callback,  String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }


  Future<String> invokeMethodString (FlutterSoundPlayerCallback callback, String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }


  Future<bool> invokeMethodBool (FlutterSoundPlayerCallback callback, String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }



  @override
  Future<bool> initializeMediaPlayer(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device, bool withUI}) async
  {
    openAudioSessionCompleter = new Completer<bool>();
    await invokeMethod( callback, 'initializeMediaPlayer', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index, 'withUI': withUI ? 1 : 0 ,},) ;
    return  openAudioSessionCompleter.future ;
  }

  @override
  Future<int> setAudioFocus(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} )
  {
    return invokeMethod( callback, 'setAudioFocus', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},);
  }

  @override
  Future<int> releaseMediaPlayer(FlutterSoundPlayerCallback callback, )
  {
    return invokeMethod( callback, 'releaseMediaPlayer',  Map<String, dynamic>(),);
  }

  @override
  Future<int> getPlayerState(FlutterSoundPlayerCallback callback, )
  {
    return invokeMethod( callback, 'getPlayerState',  Map<String, dynamic>(),);
  }
  @override
  Future<Map<String, Duration>> getProgress(FlutterSoundPlayerCallback callback, ) async
  {
    Map<String, int> m = await invokeMethod( callback, 'getPlayerState', null,) as Map;
    Map<String, Duration> r = {'duration': Duration(milliseconds: m['duration']), 'progress': Duration(milliseconds: m['progress']),};
    return r;
  }

  @override
  Future<bool> isDecoderSupported(FlutterSoundPlayerCallback callback, { Codec codec,})
  {
    return invokeMethodBool( callback, 'isDecoderSupported', {'codec': codec.index,},) as Future<bool>;
  }


  @override
  Future<int> setSubscriptionDuration(FlutterSoundPlayerCallback callback, { Duration duration,})
  {
    return invokeMethod( callback, 'setSubscriptionDuration', {'duration': duration.inMilliseconds},);
  }

  @override
  Future<Map> startPlayer(FlutterSoundPlayerCallback callback,  {Codec codec, Uint8List fromDataBuffer, String  fromURI, int numChannels, int sampleRate}) async
  {
    startPlayerCompleter = new Completer<Map>();
    await invokeMethod( callback, 'startPlayer', {'codec': codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI, 'numChannels': numChannels, 'sampleRate': sampleRate},) ;
    return  startPlayerCompleter.future ;
  }

  @override
  Future<int> feed(FlutterSoundPlayerCallback callback, {Uint8List data, })
  {
    return invokeMethod( callback, 'feed', {'data': data, },) ;
  }

  @override
  Future<Map> startPlayerFromTrack(FlutterSoundPlayerCallback callback, {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, bool removeUIWhenStopped }) async
  {
    startPlayerCompleter = new Completer<Map>();
    await invokeMethod( callback, 'startPlayerFromTrack', {'progress': progress, 'duration': duration, 'track': track, 'canPause': canPause, 'canSkipForward': canSkipForward, 'canSkipBackward': canSkipBackward,
           'defaultPauseResume': defaultPauseResume, 'removeUIWhenStopped': removeUIWhenStopped,},);
    return  startPlayerCompleter.future ;

  }

  @override
  Future<int> nowPlaying(FlutterSoundPlayerCallback callback,  {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, }) async
  {
    return invokeMethod( callback, 'nowPlaying', {'progress': progress.inMilliseconds, 'duration': duration.inMilliseconds, 'track': track, 'canPause': canPause, 'canSkipForward': canSkipForward, 'canSkipBackward': canSkipBackward,
      'defaultPauseResume': defaultPauseResume,},);
  }

  @override
  Future<int> stopPlayer(FlutterSoundPlayerCallback callback,  )
  {
    return invokeMethod( callback, 'stopPlayer',  Map<String, dynamic>(),) ;
  }

  @override
  Future<int> pausePlayer(FlutterSoundPlayerCallback callback,  )
  {
    return invokeMethod( callback, 'pausePlayer',  Map<String, dynamic>(),) ;
  }

  @override
  Future<int> resumePlayer(FlutterSoundPlayerCallback callback,  )
  {
    return invokeMethod( callback, 'resumePlayer',  Map<String, dynamic>(),) ;
  }

  @override
  Future<int> seekToPlayer(FlutterSoundPlayerCallback callback,  {Duration duration})
  {
    return invokeMethod( callback, 'seekToPlayer', {'duration': duration.inMilliseconds,},) ;
  }

  Future<int> setVolume(FlutterSoundPlayerCallback callback,  {double volume})
  {
    return invokeMethod( callback, 'setVolume', {'volume': volume,}) ;
  }

  @override
  Future<int> setUIProgressBar(FlutterSoundPlayerCallback callback, {Duration duration, Duration progress,})
  {
    return invokeMethod( callback, 'setUIProgressBar', {'duration': duration.inMilliseconds, 'progress': progress,}) ;

  }

  Future<String> getResourcePath(FlutterSoundPlayerCallback callback, )
  {
    return invokeMethodString( callback, 'getResourcePath',  Map<String, dynamic>(),) ;
  }

}