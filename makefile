main:main.vala
	valac --Xcc=-mwindows --pkg gio-2.0 --pkg glib-2.0 --pkg gobject-2.0 --pkg gstreamer-1.0 --pkg gtk+-3.0 main.vala
run:
	./main
