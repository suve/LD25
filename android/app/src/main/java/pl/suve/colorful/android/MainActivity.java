package pl.suve.colorful.android;

import org.libsdl.app.SDLActivity;

public class MainActivity extends SDLActivity {
	@Override
	protected String getMainFunction() {
		return "ld25main";
	}

	@Override
	protected String[] getLibraries() {
		return new String[] {
			"SDL2",
			"SDL2_image",
			"SDL2_mixer",
			"colorful"
		};
	}
}
