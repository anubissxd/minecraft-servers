package anubis.dashhud.mixin;

import io.redspace.ironsspellbooks.api.magic.SpellSelectionManager;
import io.redspace.ironsspellbooks.player.ClientRenderCache;
import net.minecraft.world.phys.Vec2;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Overwrite;

/**
 * Iron's Spells lays its spell bar out as a centred pyramid (1 / 2-2 / 3-3 /
 * ... / 5-5-5). We want a plain grid: rows of five, filled left to right,
 * anchored to the bottom-left corner so the mana bar can sit on top of it.
 */
@Mixin(value = ClientRenderCache.class, remap = false)
public class SpellBarLayoutMixin {
    private static final int COLUMNS = 5;

    /**
     * @author Anubis
     * @reason fixed 5-wide, bottom-left aligned grid instead of the pyramid
     */
    @Overwrite
    public static void generateRelativeLocations(SpellSelectionManager manager, int boxSize, int spriteSize) {
        ClientRenderCache.relativeSpellBarSlotLocations.clear();
        int spellCount = manager.getSpellCount();
        if (spellCount == 0) return;
        int rows = (spellCount + COLUMNS - 1) / COLUMNS;
        // SpellBarOverlay shifts everything left by (count / 3) * 5 to centre
        // the pyramid; cancel that so the grid's left edge is the anchor.
        float compensateX = (spellCount / 3) * 5;
        for (int i = 0; i < spellCount; i++) {
            int row = i / COLUMNS;
            int column = i % COLUMNS;
            float x = compensateX + column * boxSize;
            float y = (row - rows) * boxSize; // bottom row ends at the anchor
            Vec2 location = new Vec2(x, y);
            location = location.add(-spriteSize / 2f);
            ClientRenderCache.relativeSpellBarSlotLocations.add(location);
        }
    }
}
