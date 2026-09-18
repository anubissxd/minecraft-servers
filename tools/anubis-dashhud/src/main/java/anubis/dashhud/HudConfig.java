package anubis.dashhud;

import net.minecraftforge.common.ForgeConfigSpec;

/** Client config: where the dash bars sit and how the spell grid is laid out. */
public final class HudConfig {
    public enum Anchor { Hotbar, BottomLeft, BottomRight }

    public static final ForgeConfigSpec SPEC;
    public static final ForgeConfigSpec.EnumValue<Anchor> DASH_ANCHOR;
    public static final ForgeConfigSpec.IntValue DASH_X;
    public static final ForgeConfigSpec.IntValue DASH_Y;
    public static final ForgeConfigSpec.IntValue GRID_COLUMNS;
    public static final ForgeConfigSpec.BooleanValue GRID_RIGHT_ALIGNED;

    static {
        ForgeConfigSpec.Builder b = new ForgeConfigSpec.Builder();
        b.push("DashBars");
        DASH_ANCHOR = b.comment("Hotbar: Combat Dash's own xz/y config, relative to the hotbar centre.",
                        "BottomLeft / BottomRight: dashX is the distance of the bars' outer edge from that screen edge.")
                .defineEnum("dashAnchor", Anchor.BottomLeft);
        DASH_X = b.comment("Horizontal distance from the anchored screen edge (ignored for Hotbar).")
                .defineInRange("dashX", 24, -1000, 1000);
        DASH_Y = b.comment("Distance of the bars' top from the bottom of the screen (ignored for Hotbar).")
                .defineInRange("dashY", 15, -1000, 1000);
        b.pop();
        b.push("SpellGrid");
        GRID_COLUMNS = b.comment("Spells per row in Iron's Spells' spell bar.")
                .defineInRange("columns", 5, 1, 10);
        GRID_RIGHT_ALIGNED = b.comment("true: the grid grows leftwards from the anchor (use with spellBarAnchor = BottomRight).",
                        "false: it grows rightwards (BottomLeft).")
                .define("rightAligned", true);
        b.pop();
        SPEC = b.build();
    }

    private HudConfig() {}
}
