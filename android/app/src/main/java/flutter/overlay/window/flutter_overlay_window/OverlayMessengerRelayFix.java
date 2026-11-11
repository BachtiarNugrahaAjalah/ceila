package flutter.overlay.window.flutter_overlay_window;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;

public final class OverlayMessengerRelayFix {
    private OverlayMessengerRelayFix() {}

    public static void restore(BinaryMessenger binaryMessenger) {
        WindowSetup.messenger = new BasicMessageChannel<>(
                binaryMessenger,
                OverlayConstants.MESSENGER_TAG,
                JSONMessageCodec.INSTANCE);
    }
}
