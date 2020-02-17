enum State
{
    INITIALIZING_MAP,
    WAITING_FOR_PLAYER_BLOB,
    WAITING_UNTIL_PLAYER_DEATH
};

State state;

class Run
{
    float[] frametimes;
};

const u8 team = 0;
const u8 max_runs = 5;

Run[] runs(max_runs);
u8 current_run = 0;
u16 followed_id = 0;

string globalVar(const string &in name, int var)
{
    return name + "," + var + "\n";
}

string globalVar(const string &in name, bool var)
{
    return name + "," + (var ? "1" : "0") + "\n";
}

string serializeRuns()
{
    string str;

    // Slow and garbage mess to serialize frametimes
    for (int n = 0;; ++n)
    {
        bool any_column_filled = false;

        str += n + ",";

        for (int i = 0; i < runs.size(); ++i)
        {
            Run@ run = runs[i];

            if (n >= run.frametimes.size())
            {
                str += ",";
                continue;
            }

            str += run.frametimes[n] + ",";
            any_column_filled = true;
        }

        str += "\n";

        if (!any_column_filled)
        {
            break;
        }
    }

    return str;
}

void generateReport()
{
    warn("Generating CSV.");

    string str;
    str += "KING ARTHUR'S GOLD BENCHMARK REPORT\n";
    str += "runs;" + max_runs + "\n";

    str += "resolution;" + getDriver().getScreenWidth() + "," + getDriver().getScreenHeight() + "\n";

    str += globalVar("Recording mode", g_videorecording);
    str += globalVar("HUD", v_drawhud);

    str += globalVar("Minimap", v_showminimap);

    str += globalVar("HQ2X", v_postprocess);
    str += globalVar("HQ2X (sprites)", v_smoothsprites);
    str += globalVar("HQ2X (map)", v_smoothmap);

    str += globalVar("Fast render", v_fastrender);

    str += globalVar("VSync", v_vsync);
    str += globalVar("Capped framerate", v_capped);

    str += globalVar("Debug", g_debug);

    str += globalVar("Kids safe (no blood etc.)", g_kidssafe);

    str += globalVar("Chat bubbles", cl_chatbubbles);

//    str += globalVar("No render scale", v_no_renderscale);

    str += globalVar("Sound", s_soundon);
    str += globalVar("Volume", s_volume);
    str += globalVar("Music volume", s_musicvolume);
    str += globalVar("Game music", s_gamemusic);
    str += globalVar("Ambient music", s_ambientmusic);

    // Debugging tools
    str += globalVar("Script watchdog", g_timeoutscripts);
    str += globalVar("FPS counter", v_showfps);
    str += globalVar("Network graph", n_graph);
    str += globalVar("Particles graph", g_particlegraph);
    str += globalVar("Physics graph", g_physicsgraph);
    str += globalVar("Deltatime diagnostics", v_deltatime_diag);

    {
        ConfigFile benchmark_info;
        benchmark_info.add_string("v", str);
        
        if (!benchmark_info.saveFile("benchmark-info.cfg"))
        {
            error("Failed to save benchmark info!");
        }
    }

    {
        ConfigFile benchmark_data;
        benchmark_data.add_string("v", serializeRuns());

        if (!benchmark_data.saveFile("benchmark-data.cfg"))
        {
            error("Failed to save benchmark data!");
        }
    }

    {
        // Abusing cfgs syntax here for the first line
        string str;
        str += "'benchmark-data.cfg'\n";
        str += "set autoscale fix\n";
        str += "set key outside right center\n";
        str += "set datafile separator ','\n";
        str += "set xlabel 'Frame'\n";
        str += "set ylabel 'Frametime (ms)'\n";
        str += "set yrange [0:30]\n";

        str += "set terminal pngcairo size 2560,1440 enhanced font 'Verdana,9'\n";
        str += "set output 'benchmark.png'\n";

        str += "plot for [col=3:" + (runs.size() + 1) + "] bench using 1:col title 'Run ' . (col-2) with points";

        ConfigFile gnuplot_script;
        gnuplot_script.add_string("bench", str);

        if (!gnuplot_script.saveFile("gnuplot-benchmark.cfg"))
        {
            error("Failed to save gnuplot script!");
        }
    }
}

void nextRun()
{
    if (current_run >= max_runs)
    {
        print("Done!");
        generateReport();
        QuitGame();
    }

    ++current_run;
    state = INITIALIZING_MAP;
}

CBlob@[]@ getKegs()
{
    CBlob@[] kegs;
    getBlobsByName("keg", @kegs);
    return @kegs;
}

CBlob@ spawnMoron(const string &in blobName, int team, const Vec2f &in position)
{
    CBlob@ blob = server_CreateBlob(blobName, team, position);

    blob.setKeyPressed(key_up, true);

    return blob;
}

void spawnBaseBenchmarkBlobs()
{
    CMap@ map = getMap();

    for (int i = 0; i < 30; ++i)
    {
        string name;

        switch (i % 3)
        {
        case 0: name = "knight"; break;
        case 1: name = "archer"; break;
        case 2: name = "builder"; break;
        }

        const float x = 200.0f + i * 24.0f;
        const float y = (map.getLandYAtX(x / map.tilesize) * map.tilesize) - 32.0f;
        const int team = i % 2;

        CBlob@ blob = spawnMoron(name, team, Vec2f(x, y));
    }

    CBlob@[]@ kegs = getKegs();

    for (int i = 0; i < kegs.size(); ++i)
    {
        CBlob@ keg = kegs[i];
        keg.getShape().SetStatic(false);
        keg.SendCommand(keg.getCommandID("activate"));
    }
}

void initializePlayerBlob(CPlayer@ player, CBlob@ blob)
{
    CControls@ controls = blob.getControls();
    CCamera@ camera = getCamera();

    blob.server_SetPlayer(null);
    controls.setMousePosition(Vec2f_zero);

    camera.mousecamstyle = 1;
}

void onInit(CRules@ rules)
{
    print("Reached initialization in rules at " + Time());
    rules.RemoveScript("PlayerCamera.as"); // The camera is OURS!
    nextRun();
}

void onTick(CRules@ rules)
{
    if (state == INITIALIZING_MAP)
    {
        LoadMap("benchmarkmap.png");
        warn("CURRENTLY EXECUTING RUN " + current_run + "!");
        state = WAITING_FOR_PLAYER_BLOB;
    }
    else if (state == WAITING_FOR_PLAYER_BLOB)
    {
        CPlayer@ player = getLocalPlayer();
        CBlob@ blob = getLocalPlayerBlob();

        if (blob !is null)
        {
            followed_id = blob.getNetworkID();

            rules.SetCurrentState(GAME);
            initializePlayerBlob(player, blob);
            spawnBaseBenchmarkBlobs();

            state = WAITING_UNTIL_PLAYER_DEATH;
        }

        CBlob@[]@ kegs = getKegs();
        
        for (int i = 0; i < kegs.size(); ++i)
        {
            CBlob@ keg = kegs[i];
            keg.getShape().SetStatic(true);
        }
    }
    else if (state == WAITING_UNTIL_PLAYER_DEATH)
    {
        CBlob@ blob = getBlobByNetworkID(followed_id);
        if (blob == null || blob.getHealth() <= 0.0f)
        {
            nextRun();
        }
    }

    CBlob@ tracked_blob = getBlobByNetworkID(followed_id);
    if (tracked_blob !is null)
    {
        tracked_blob.setKeyPressed(key_right, true);
        tracked_blob.setKeyPressed(key_action1, true);
    }
}

void onRender(CRules@ rules)
{
    if (state == WAITING_UNTIL_PLAYER_DEATH)
    {
        Run@ run = @runs[current_run - 1];

        // TODO : delta time is capped at at least 30Hz, so that is bad...
        run.frametimes.push_back(1000.0f * getRenderExactDeltaTime());
    }

    CBlob@ blob = getBlobByNetworkID(followed_id);
    CCamera@ camera = getCamera();

    if (blob !is null && camera !is null)
    {
        camera.setPosition(blob.getInterpolatedPosition());
    }
}

void onPlayerRequestSpawn(CRules@ rules, CPlayer@ player)
{
    if (player is getLocalPlayer() && player.getTeamNum() != team)
    {
        player.client_ChangeTeam(team);
    }
}
