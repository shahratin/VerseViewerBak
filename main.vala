// modules: gio-2.0 glib-2.0 gobject-2.0 gstreamer-1.0 gtk+-3.0

using GLib;
using Gtk;

static TextView text_view;
Gtk.ComboBox combobox;
Gtk.SpinButton  select_sura_box;
Gtk.SpinButton select_aya_box;
Gtk.ToggleButton btn_play_mode;
bool cont = false;
double surano = 0;
double ayano = 0;
enum Column { sura }
const int ayatInSura[114] = {
	    7,  286, 200, 176, 120, 165, 206, 75,  129, 109, 123, 111, 43,
	    52, 99,  128, 111, 110, 98,  135, 112, 78,  118, 64,  77,  227,
	    93, 88,  69,  60,  34,  30,  73,  54,  45,  83,  182, 88,  75,
	    85, 54,  53,  89,  59,  37,  35,  38,  29,  18,  45,  60,  49,
	    62, 55,  78,  96,  29,  22,  24,  13,  14,  11,  11,  18,  12,
	    12, 30,  52,  52,  44,  28,  28,  20,  56,  40,  31,  50,  40,
	    46, 42,  29,  19,  36,  25,  22,  17,  19,  26,  30,  20,  15,
	    21, 11,  8,   8,   19,  5,   8,   8,   11,  11,  8,   3,   9,
	    5,  4,   7,   3,   6,   3,   5,   4,   5,   6};
int getAddress(int sura, int ayat) {
	
	int ayatsInPreviousSuras = 0;
	for (int i = 0; i < sura; i++) {
		ayatsInPreviousSuras = ayatsInPreviousSuras + ayatInSura[i];
	}
	return (ayatsInPreviousSuras + ayat);
}
string getText(int index, string path) {
	var file = File.new_for_path(path);
	string[] arrayOfAyat = {};

	if (!file.query_exists()) {
		stderr.printf("File '%s' doesn't exist.\n", file.get_path());
	}
	try {
		var dis = new DataInputStream(file.read());
		string line;
		while ((line = dis.read_line(null)) != null) {
     
	if (line.split("|").length >1){
		arrayOfAyat += line.split("|")[2];
	}else{
		arrayOfAyat += line;
	}
}
	} catch (Error e) {
		error("%s", e.message);
	}
	return arrayOfAyat[index];
}

static void main(string[] args) {
	Gtk.init(ref args);
	Gst.init(ref args);

	var window_main = new Window();
	try {
		window_main.icon = new Gdk.Pixbuf.from_file ("icon.ico");
	} catch (Error e) {
		stderr.printf ("Could not load application icon: %s\n", e.message);
	}
	window_main.title = "Verse viewer";
	window_main.set_default_size(400, 500);
	window_main.destroy.connect(Gtk.main_quit);
	var css_provider = new Gtk.CssProvider();
	string path = "styleapp.css";
	var screen = window_main.get_screen();
	var cssfile = File.new_for_path("styleapp.css");
	if (FileUtils.test(path, FileTest.EXISTS)) {
		try {
			css_provider.load_from_file(cssfile);
			Gtk.StyleContext.add_provider_for_screen(
			    screen, css_provider,
			    Gtk.STYLE_PROVIDER_PRIORITY_USER);
		} catch (Error e) {
			error("Cannot load CSS stylesheet: %s", e.message);
		}
	};
	
	var vbox_main = new Box(Orientation.VERTICAL, 0);
	var header_bar = new HeaderBar();
	var hbox_nav = new Box(Orientation.HORIZONTAL, 0);
	select_sura_box = new SpinButton.with_range(1, 114, 1);
	select_aya_box = new SpinButton.with_range(1, 300, 1);
	select_sura_box.adjustment.value_changed.connect(() => {
		surano = select_sura_box.adjustment.value - 1;
		select_aya_box.set_range(1, ayatInSura[(int)surano]);
		select_aya_box.adjustment.value = 1;
		combobox.set_active((int)surano);
		on_btn_show_clicked();
	});
	select_aya_box.adjustment.value_changed.connect(() => {
		ayano = select_aya_box.adjustment.value - 1;
		on_btn_show_clicked();
	});
	text_view = new TextView();
	text_view.editable = false;
	text_view.cursor_visible = false;

	var scroll = new ScrolledWindow(null, null);
	scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
	scroll.set_placement(Gtk.CornerType.TOP_RIGHT);

	var btn_show = new Button.with_label("Show");
	var btn_next = new Button.with_label("Next");
	var btn_listen = new Button.with_label("Listen");
	btn_play_mode = new ToggleButton.with_label("Continuous");
	btn_show.clicked.connect(on_btn_show_clicked);
	btn_next.clicked.connect(on_btn_next_clicked);
	btn_listen.clicked.connect(on_btn_listen_clicked);
	btn_play_mode.clicked.connect(on_btn_play_mode_clicked);

	string[] sura_list = {};
	var file = File.new_for_path("text/sura_list_en.txt");
	if (!file.query_exists()) {
	}

	try {
		var dis = new DataInputStream(file.read());
		string line;
		while ((line = dis.read_line(null)) != null) {
			sura_list += line;
		}
	} catch (Error e) {
		error("%s", e.message);
	}

	var liststore = new Gtk.ListStore(1, typeof(string));
	for (int i = 0; i < sura_list.length; i++) {
		Gtk.TreeIter iter;
		liststore.append(out iter);
		liststore.set(iter, Column.sura, sura_list[i]);
	}

	combobox = new Gtk.ComboBox.with_model(liststore);

	Gtk.CellRendererText cell = new Gtk.CellRendererText();
	Gtk.CellRendererPixbuf cell_pb = new Gtk.CellRendererPixbuf();
	combobox.pack_start(cell_pb, false);
	combobox.pack_start(cell, false);
	combobox.set_attributes(cell, "text", Column.sura);
	combobox.set_active((int)surano);
	combobox.changed.connect(() => {

		select_sura_box.adjustment.value =
		    1 + (double)combobox.get_active();
	});

	scroll.add(text_view);

	vbox_main.pack_start(scroll, true, true);

	hbox_nav.add(select_sura_box);
	hbox_nav.add(select_aya_box);
	hbox_nav.add(combobox);
	hbox_nav.add(btn_listen);
	hbox_nav.add(btn_play_mode);
	hbox_nav.add(btn_show);
	hbox_nav.add(btn_next);


	hbox_nav.get_style_context().add_class("my_combobox");
	header_bar.add(hbox_nav);
	header_bar.set_show_close_button(true);
	header_bar.show_all();
	window_main.add(vbox_main);
	window_main.set_titlebar(header_bar);
	window_main.show_all();
	select_aya_box.set_range(1, ayatInSura[(int)surano]);
	on_btn_show_clicked();

	Gtk.main();
}

static void on_btn_show_clicked() {
  	string q, e, b, qx, ex, bx, empty;
  	q = getText(getAddress((int)surano, (int)ayano),
			   "text/quran/quran-simple.txt");
  	e = getText(getAddress((int)surano, (int)ayano),
		    "text/trans/en.yusufali.trans/en.yusufali.txt");
  	b = getText(getAddress((int)surano, (int)ayano),
		  "text/trans/bn.bengali.trans/bn.bengali.txt") ;
	
	empty = "<span face=\"Al Qalam Quran Majeed\" size=\"small\" style=\"normal\" weight=\"normal\">%s\n</span>".printf(" ");
	qx = "<span face=\"Al Qalam Quran Majeed\" size=\"xx-large\" style=\"normal\" weight=\"normal\">%s\n</span>".printf(q);
	ex = "<span face=\"Georgia\" size=\"medium\" weight=\"light\">%s\n</span>".printf(e);
	bx = "<span face=\"Lohit Bengali\" size=\"medium\" weight=\"normal\">%s\n</span>".printf(b);

	TextIter start, end;
	text_view.buffer.get_start_iter(out start);
	text_view.buffer.get_end_iter(out end);

	text_view.buffer.delete(ref start, ref end);
	text_view.buffer.insert_markup(ref end, empty, -1);
	text_view.buffer.insert_markup(ref end, qx, -1);
	text_view.buffer.insert_markup(ref end, empty, -1);
	text_view.buffer.insert_markup(ref end, bx, -1);
	text_view.buffer.insert_markup(ref end, ex, -1);

	text_view.get_style_context().add_class("my_class");
	text_view.set_wrap_mode(Gtk.WrapMode.WORD);
	text_view.set_justification(Gtk.Justification.CENTER);
}

public
class StreamPlayer {
	public Gst.State state;
	public string s;
       private
	MainLoop loop = new MainLoop();
	private
	void foreach_tag(Gst.TagList list, string tag) {
		switch (tag) {
			case "title":
				string tag_string;
				list.get_string(tag, out tag_string);
				stdout.printf("tag: %s = %s\n", tag,
					      tag_string);
				break;
			default:
				break;
		}
	}
	private
	bool bus_callback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
			case Gst.MessageType.ERROR:
				GLib.Error err;
				string debug;
				message.parse_error(out err, out debug);
				stdout.printf("Error: %s\n", err.message);
				loop.quit();
				break;
			case Gst.MessageType.EOS:
				stdout.printf("end of stream\n");
				if(cont){
					on_btn_next_clicked();
					on_btn_listen_clicked();
					}else{
					;
				}
				break;
			case Gst.MessageType.STATE_CHANGED:
				Gst.State oldstate;
				Gst.State newstate;
				Gst.State pending;
				message.parse_state_changed(
				    out oldstate, out newstate, out pending);
				stdout.printf("state changed: %s->%s:%s\n",
					      oldstate.to_string(),
					      newstate.to_string(),
					      pending.to_string());
				break;
			case Gst.MessageType.TAG:
				Gst.TagList tag_list;
				stdout.printf("taglist found\n");
				message.parse_tag(out tag_list);
				tag_list.foreach (
				    (Gst.TagForeachFunc)foreach_tag);
				break;
			default:
				break;
		}

		return true;
	}
       public
	void play(string stream) {
		dynamic Gst.Element play =
		    Gst.ElementFactory.make("playbin", "play");
		play.uri = stream;

		Gst.Bus bus = play.get_bus();
		bus.add_watch(GLib.Priority.HIGH_IDLE, bus_callback);

		play.set_state(Gst.State.NULL);
		play.set_state(Gst.State.READY);
		play.set_state(Gst.State.PLAYING);
		play.get_state(out state, null, Gst.CLOCK_TIME_NONE);
		s = Gst.Element.state_get_name (state);

		loop.run();
	}
}

public static void
on_btn_listen_clicked() {
	var player = new StreamPlayer();
	print(player.s);
	string formatted_sura = "%03d".printf((int)surano + 1);
	string formatted_aya = "%03d".printf((int)ayano + 1);
	string dir;
	dir = "/afasy-64kbps-offline/";
	var filename = "file:///"+GLib.Environment.get_current_dir() + dir +
		       formatted_sura + "/" + formatted_sura + formatted_aya +
		       ".mp3";
	player.play(filename.replace("\\", "/"));
	//  print(player.s);
	while (player.s != "PLAYING"){
		//  print(player.s);
	}
}
public static void
on_btn_next_clicked() {
	//  print(surano.to_string());
	//  print("\n");
	//  print(ayano.to_string());
	//  print("\n");
	//  print(ayatInSura[(int)surano].to_string());
	//  print("\n");
	if(ayano<ayatInSura[(int)surano]-1){
		select_aya_box.spin(STEP_FORWARD, 1);
		//  ayano++;
		//  on_btn_show_clicked();
	}else{
		//  surano++;
		//  ayano = 0;
		//  on_btn_show_clicked();
		select_sura_box.spin(STEP_FORWARD, 1);
	}
}
public static void
on_btn_play_mode_clicked() {
	if (cont == true){
		cont = false;
	}else{
		cont=true;
	}
	print(cont.to_string());
}