export 'breakpoints.dart';
export 'video_player/video_player_strategy.dart';

export 'video_player/video_player_web_impl.dart'
    if (dart.library.io) 'video_player/video_player_web_stub.dart';

export 'video_player/video_player_mobile_impl.dart'
    if (dart.library.js_interop) 'video_player/video_player_mobile_stub.dart';

export 'fullscreen/fullscreen_manager.dart';
