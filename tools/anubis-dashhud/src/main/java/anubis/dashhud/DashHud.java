package anubis.dashhud;

import com.mojang.blaze3d.platform.InputConstants;
import com.mojang.blaze3d.systems.RenderSystem;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.ai.attributes.Attribute;
import net.minecraft.world.entity.ai.attributes.AttributeInstance;
import net.minecraft.world.entity.player.Player;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.client.event.RenderGuiEvent;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.common.capabilities.Capability;
import net.minecraftforge.common.util.LazyOptional;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.DistExecutor;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.registries.ForgeRegistries;

import java.lang.reflect.Field;

/**
 * Anubis Dash HUD - draws Combat Dash's dash bars itself, so they never fade
 * out when full and never hide because of an offhand item. Reads Combat
 * Dash's data by reflection, so it
 * has no compile-time dependency and never touches the original mod.
 */
@Mod("anubis_dashhud")
public class DashHud {
    private static final ResourceLocation BACK = new ResourceLocation("combat_dash", "textures/screens/arrowback.png");
    private static final ResourceLocation FILL = new ResourceLocation("combat_dash", "textures/screens/arrow_1401.png");
    private static final ResourceLocation MOUSE_ICONS = new ResourceLocation("spell_engine", "textures/hud/widgets.png");

    private static Capability<Object> playerVarsCap;
    private static Field dashCooldownField;
    private static KeyMapping dashKey;
    private static Object cfgX, cfgY;
    private static boolean lookedUp = false;
    private static final org.slf4j.Logger LOG = com.mojang.logging.LogUtils.getLogger();
    private static long lastDebug = 0;
    private static void debug(String why) {
        long now = System.currentTimeMillis();
        if (now - lastDebug > 10000) { lastDebug = now; LOG.info("[anubis_dashhud] not drawing: {}", why); }
    }

    public DashHud() {
        net.minecraftforge.fml.ModLoadingContext.get().registerConfig(net.minecraftforge.fml.config.ModConfig.Type.CLIENT, HudConfig.SPEC, "anubis_dashhud-client.toml");
        DistExecutor.unsafeRunWhenOn(Dist.CLIENT, () -> () -> MinecraftForge.EVENT_BUS.register(DashHud.class));
    }

    @SuppressWarnings("unchecked")
    private static void lookup() {
        lookedUp = true;
        try {
            Class<?> vars = Class.forName("combat_dash.network.CombatDashModVariables");
            playerVarsCap = (Capability<Object>) vars.getField("PLAYER_VARIABLES_CAPABILITY").get(null);
            dashCooldownField = Class.forName("combat_dash.network.CombatDashModVariables$PlayerVariables").getField("DashCooldown");
            dashKey = (KeyMapping) Class.forName("combat_dash.init.CombatDashModKeyMappings").getField("DASH").get(null);
            Class<?> cfg = Class.forName("combat_dash.configuration.CombatDashClientConfiguration");
            cfgX = cfg.getField("DASHCONFIGXZPOS").get(null);
            cfgY = cfg.getField("DASHCONFIGYPOS").get(null);
        } catch (Throwable t) {
            playerVarsCap = null;
            LOG.warn("[anubis_dashhud] lookup failed", t);
        }
    }

    private static double cfgValue(Object configValue, double fallback) {
        try { return ((Number) configValue.getClass().getMethod("get").invoke(configValue)).doubleValue(); }
        catch (Throwable t) { return fallback; }
    }

    private static AttributeInstance attrInst(Player p, String id) {
        Attribute a = ForgeRegistries.ATTRIBUTES.getValue(new ResourceLocation("combat_dash", id));
        return a == null ? null : p.getAttribute(a);
    }

    @SubscribeEvent
    public static void onRender(RenderGuiEvent.Post event) {
        Minecraft mc = Minecraft.getInstance();
        Player player = mc.player;
        if (player == null || mc.options.hideGui) return;
        if (!lookedUp) lookup();
        if (playerVarsCap == null) { debug("lookup failed"); return; }

        double cooldown;
        try {
            LazyOptional<Object> opt = player.getCapability(playerVarsCap, null);
            Object vars = opt.orElse(null);
            cooldown = vars == null ? Double.MAX_VALUE : dashCooldownField.getDouble(vars); // no sync yet = show full
        } catch (Throwable t) { debug("cap read: " + t); return; }

        AttributeInstance maxInst = attrInst(player, "max_dash_amount");
        int bars = maxInst == null ? 3 : (int) maxInst.getValue();
        if (bars <= 0) bars = 3;
        AttributeInstance cdInst = attrInst(player, "dash_cool_down");
        double perBar = cdInst == null ? 0 : cdInst.getBaseValue();
        if (perBar <= 0) { debug("dash_cool_down base=" + perBar); return; }

        int screenW = event.getWindow().getGuiScaledWidth();
        int screenH = event.getWindow().getGuiScaledHeight();
        // baseX is the rightmost bar; the others step 5 to the left of it
        int baseX, baseY;
        switch (HudConfig.DASH_ANCHOR.get()) {
            case BottomLeft -> {
                baseX = HudConfig.DASH_X.get() + (bars - 1) * 5 + 1;
                baseY = HudConfig.DASH_Y.get();
            }
            case BottomRight -> {
                baseX = screenW - HudConfig.DASH_X.get() - 10;
                baseY = HudConfig.DASH_Y.get();
            }
            default -> {
                baseX = screenW / 2 + (int) (cfgValue(cfgX, -114) + 8.0);
                baseY = (int) cfgValue(cfgY, 16);
            }
        }

        GuiGraphics g = event.getGuiGraphics();
        RenderSystem.enableBlend();
        RenderSystem.setShader(GameRenderer::getPositionTexShader);
        RenderSystem.defaultBlendFunc();
        RenderSystem.setShaderColor(1f, 1f, 1f, 1f);
        int leftmost = Integer.MAX_VALUE;
        for (int i = 0; i < bars; i++) {
            int x = baseX - i * 5;
            int y = screenH - baseY;
            leftmost = Math.min(leftmost, x - 1);
            g.blit(BACK, x - 1, y - 1, 0, 0, 11, 13, 11, 13);
            double fill = Math.max(0.0, Math.min(1.0, (cooldown - i * perBar) / perBar));
            int barHeight = (int) (11.0 * (1.0 - fill));
            g.blit(FILL, x, y, 0, 0, 9, barHeight, 9, 11);
        }
        // keybinding hint to the left of the bars: Spell Engine's mouse icons
        // for mouse buttons (same look as its spell hotbar), key name otherwise
        if (dashKey != null) {
            int hintY = screenH - baseY;
            InputConstants.Key key = dashKey.getKey();
            if (key.getType() == InputConstants.Type.MOUSE) {
                int u, v;
                switch (key.getValue()) {
                    case 0 -> { u = 0; v = 0; }    // left
                    case 1 -> { u = 16; v = 0; }   // right
                    case 2 -> { u = 32; v = 0; }   // middle
                    case 3 -> { u = 0; v = 16; }   // button 4
                    case 4 -> { u = 16; v = 16; }  // button 5
                    default -> { u = 32; v = 16; }
                }
                int iconX = baseX - (bars - 1) * 5 / 2 - 1; // centred above the bars
                g.blit(MOUSE_ICONS, iconX, hintY - 13, u, v, 10, 12, 256, 256);
            } else {
                String label = dashKey.getTranslatedKeyMessage().getString();
                int tw = mc.font.width(label);
                g.drawString(mc.font, label, baseX - (bars - 1) * 5 / 2 + 4 - tw / 2, hintY - 10, 0xFFFFFF, true);
            }
        }
    }
}
