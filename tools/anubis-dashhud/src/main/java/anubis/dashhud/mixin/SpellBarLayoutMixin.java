package anubis.dashhud.mixin;

import anubis.dashhud.HudConfig;
import io.redspace.ironsspellbooks.api.magic.SpellSelectionManager;
import io.redspace.ironsspellbooks.player.ClientRenderCache;
import net.minecraft.world.phys.Vec2;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Overwrite;

/**
 * Iron's Spells lays its spell bar out as a centred pyramid (1 / 2-2 / 3-3 /
 * ... / 5-5-5). We want a plain grid with a fixed number of columns, filled
 * left to right from the bottom row up, hugging the screen corner it is
 * anchored to.
 */
@Mixin(value = ClientRenderCache.class, remap = false)
public class SpellBarLayoutMixin {
    /**
     * @author Anubis
     * @reason fixed-width, corner-aligned grid instead of the pyramid
     */
    @Overwrite
    public static void generateRelativeLocations(SpellSelectionManager manager, int boxSize, int spriteSize) {
        ClientRenderCache.relativeSpellBarSlotLocations.clear();
        int spellCount = manager.getSpellCount();
        if (spellCount == 0) return;
        int columns = HudConfig.GRID_COLUMNS.get();
        boolean rightAligned = HudConfig.GRID_RIGHT_ALIGNED.get();
        // SpellBarOverlay shifts everything left by (count / 3) * 5 to centre
        // the pyramid; cancel that so the anchor is the grid's own edge.
        float compensateX = (spellCount / 3) * 5;
        // width of a full row: frames are spriteSize wide and overlap by (spriteSize - boxSize)
        float rowWidth = (columns - 1) * boxSize + spriteSize;
        for (int i = 0; i < spellCount; i++) {
            int row = i / columns;
            int column = i % columns;
            // SpellBarOverlay draws each spriteSize box at anchor + location, so
            // with offsets 0/0 the grid sits flush in the corner.
            float x = compensateX + column * boxSize - (rightAligned ? rowWidth : 0);
            float y = -spriteSize - row * boxSize; // first row at the bottom, later rows stack upward
            ClientRenderCache.relativeSpellBarSlotLocations.add(new Vec2(x, y));
        }
    }
}
