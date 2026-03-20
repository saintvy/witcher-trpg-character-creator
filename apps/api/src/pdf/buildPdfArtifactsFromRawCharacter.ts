type PdfOptions = { alchemy_style?: 'w1' | 'w2' };

export type BuildPdfArtifactDeps = {
  db: {
    query: (...args: any[]) => Promise<{ rows: any[] }>;
  };
  DEFAULT_USER_SETTINGS: {
    useW1AlchemyIcons: boolean;
    pdfTables: unknown;
  };
  normalizeUserSettingsRow: (...args: any[]) => {
    useW1AlchemyIcons: boolean;
    pdfTables: unknown;
  };
  resolveCharacterRawI18n: (...args: any[]) => Promise<Record<string, unknown>>;
  readIdListFromGear: (...args: any[]) => string[];
  readIdListFromGearAny: (...args: any[]) => string[];
  readIdListFromIngredients: (...args: any[]) => string[];
  readIdListFromMagicList: (...args: any[]) => string[];
  readIdListFromMagicInvocations: (...args: any[]) => string[];
  readIdListFromMagicGifts: (...args: any[]) => string[];
  ITEM_ID_RE: {
    weapon: RegExp;
    armor: RegExp;
    potion: RegExp;
    recipe: RegExp;
    upgrade: RegExp;
    blueprint: RegExp;
    generalGear: RegExp;
    vehicle: RegExp;
  };
  patchResolvedGearFromDbViews: (...args: any[]) => void;
  getSkillsCatalog: (...args: any[]) => Promise<{ skills?: Array<{ id: string; param: string | null; name: string }> }>;
  loadAvatarFromStorage: (...args: any[]) => Promise<{ data: Buffer; contentType: string } | null>;
  generateCharacterPdfBuffer: (params: {
    rawCharacter: Record<string, unknown>;
    resolvedCharacter: Record<string, unknown>;
    lang: string;
    skillsCatalogById: Map<string, { param: string | null; name?: string }>;
    itemEffectsGlossary: Array<{ name: string; value: string }>;
    avatarBuffer?: Buffer;
  }) => Promise<Buffer>;
  safeFileNameBase: (...args: any[]) => string;
};

function parseAvatarDataUrlBuffer(value: unknown): Buffer | undefined {
  if (typeof value !== 'string') return undefined;
  const match = /^data:([^;,]+)?;base64,(.+)$/i.exec(value.trim());
  if (!match?.[2]) return undefined;
  try {
    return Buffer.from(match[2], 'base64');
  } catch {
    return undefined;
  }
}

export async function buildPdfArtifactsFromRawCharacter(params: {
  rawCharacter: Record<string, unknown>;
  lang: string;
  ownerEmail?: string | null;
  explicitName?: string | null;
  avatarUrl?: string | null;
  options?: PdfOptions;
  deps: BuildPdfArtifactDeps;
}) {
  const {
    rawCharacter,
    lang,
    ownerEmail = null,
    explicitName = null,
    avatarUrl = null,
    options,
    deps,
  } = params;

  let userSettings = deps.DEFAULT_USER_SETTINGS;
  if (ownerEmail) {
    try {
      const settingsResult = await deps.db.query(
        `
          SELECT owner_email, settings_json
          FROM wcc_user_settings
          WHERE owner_email = $1
        `,
        [ownerEmail],
      );
      userSettings = deps.normalizeUserSettingsRow(settingsResult.rows[0]);
    } catch (error) {
      console.error('[characters] pdf user settings lookup failed, using defaults', error);
    }
  }

  const useW1AlchemyIcons =
    options?.alchemy_style === 'w1'
      ? true
      : options?.alchemy_style === 'w2'
        ? false
        : userSettings.useW1AlchemyIcons;

  const rawCharacterForPdf: Record<string, unknown> = {
    ...rawCharacter,
    user_settings: {
      use_w1_alchemy_icons: useW1AlchemyIcons,
      pdf_tables: userSettings.pdfTables,
    },
  };

  const resolvedCharacter = await deps.resolveCharacterRawI18n(rawCharacter, lang);
  const weaponIds = deps.readIdListFromGear(rawCharacter, 'weapons', 'w_id', deps.ITEM_ID_RE.weapon);
  const armorIds = deps.readIdListFromGear(rawCharacter, 'armors', 'a_id', deps.ITEM_ID_RE.armor);
  const potionIds = deps.readIdListFromGear(rawCharacter, 'potions', 'p_id', deps.ITEM_ID_RE.potion);
  const recipeIds = deps.readIdListFromGearAny(rawCharacter, 'recipes', ['r_id', 'id'], deps.ITEM_ID_RE.recipe);
  const upgradeIds = deps.readIdListFromGearAny(rawCharacter, 'upgrades', ['u_id', 'id'], deps.ITEM_ID_RE.upgrade);
  const blueprintIds = deps.readIdListFromGearAny(rawCharacter, 'blueprints', ['b_id', 'bp_id', 'id'], deps.ITEM_ID_RE.blueprint);
  const generalGearIds = deps.readIdListFromGearAny(rawCharacter, 'general_gear', ['t_id', 'id'], deps.ITEM_ID_RE.generalGear);
  const vehicleIds = deps.readIdListFromGearAny(rawCharacter, 'vehicles', ['wt_id', 'id'], deps.ITEM_ID_RE.vehicle);
  const ingredientAlchemyIds = deps.readIdListFromIngredients(rawCharacter, 'alchemy', 'i_id');
  const ingredientCraftIds = deps.readIdListFromIngredients(rawCharacter, 'craft', 'i_id');
  const ingredientIds = Array.from(new Set([...ingredientAlchemyIds, ...ingredientCraftIds]));
  const spellIds = deps.readIdListFromMagicList(rawCharacter, 'spells');
  const signIds = deps.readIdListFromMagicList(rawCharacter, 'signs');
  const ritualIds = deps.readIdListFromMagicList(rawCharacter, 'rituals');
  const hexIds = deps.readIdListFromMagicList(rawCharacter, 'hexes');
  const invocationDruidIds = deps.readIdListFromMagicInvocations(rawCharacter, 'druid');
  const invocationPriestIds = deps.readIdListFromMagicInvocations(rawCharacter, 'priest');
  const magicSpellLikeIds = Array.from(new Set([...spellIds, ...signIds]));
  const magicInvocationIds = Array.from(new Set([...invocationDruidIds, ...invocationPriestIds]));
  const giftIds = deps.readIdListFromMagicGifts(rawCharacter);

  const weaponsById = new Map<string, any>();
  const armorsById = new Map<string, any>();
  const potionsById = new Map<string, any>();
  const recipesById = new Map<string, any>();
  const blueprintsById = new Map<string, any>();
  const ingredientsById = new Map<string, any>();
  const generalGearById = new Map<string, any>();
  const vehiclesById = new Map<string, any>();
  const magicSpellsById = new Map<string, any>();
  const magicInvocationsById = new Map<string, any>();
  const magicRitualsById = new Map<string, any>();
  const magicHexesById = new Map<string, any>();
  const giftsById = new Map<string, any>();
  const itemEffectsGlossary: Array<{ name: string; value: string }> = [];

  try {
    if (weaponIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT w_id, weapon_name, dmg, dmg_types, weight, price, hands, reliability, concealment, effect_names
          FROM wcc_item_weapons_v
          WHERE lang = $1 AND w_id = ANY($2::text[])
        `,
        [lang, weaponIds],
      );
      rows.forEach((r: any) => weaponsById.set(r.w_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf weapon lookup failed', error);
  }

  try {
    if (armorIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT a_id, armor_name, stopping_power, encumbrance, enhancements, weight, price, effect_names
          FROM wcc_item_armors_v
          WHERE lang = $1 AND a_id = ANY($2::text[])
        `,
        [lang, armorIds],
      );
      rows.forEach((r: any) => armorsById.set(r.a_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf armor lookup failed', error);
  }

  try {
    if (potionIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT p_id, potion_name, toxicity, time_effect, effect, weight, price
          FROM wcc_item_potions_v
          WHERE lang = $1 AND p_id = ANY($2::text[])
        `,
        [lang, potionIds],
      );
      rows.forEach((r: any) => potionsById.set(r.p_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf potion lookup failed', error);
  }

  try {
    if (recipeIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT r_id, recipe_name, recipe_group, craft_level, complexity, time_craft, formula_en,
                 price_formula, minimal_ingredients_cost, time_effect, toxicity, recipe_description,
                 weight_potion, price_potion
          FROM wcc_item_recipes_v
          WHERE lang = $1 AND r_id = ANY($2::text[])
        `,
        [lang, recipeIds],
      );
      rows.forEach((r: any) => recipesById.set(r.r_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf recipe lookup failed', error);
  }

  try {
    if (blueprintIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT b_id, blueprint_name, blueprint_group, craft_level, difficulty_check, time_craft,
                 item_id, components, item_desc, price_components, price, price_item
          FROM wcc_item_blueprints_v
          WHERE lang = $1 AND b_id = ANY($2::text[])
        `,
        [lang, blueprintIds],
      );
      rows.forEach((r: any) => blueprintsById.set(r.b_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf blueprint lookup failed', error);
  }

  try {
    if (ingredientIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT i_id, ingredient_name, alchemy_substance, alchemy_substance_en, harvesting_complexity, weight, price
          FROM wcc_item_ingredients_v
          WHERE lang = $1 AND i_id = ANY($2::text[])
        `,
        [lang, ingredientIds],
      );
      rows.forEach((r: any) => ingredientsById.set(r.i_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf ingredient lookup failed', error);
  }

  try {
    if (generalGearIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT t_id, gear_name, group_name, subgroup_name, gear_description, concealment, weight, price
          FROM wcc_item_general_gear_v
          WHERE lang = $1 AND t_id = ANY($2::text[])
        `,
        [lang, generalGearIds],
      );
      rows.forEach((r: any) => generalGearById.set(r.t_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf general gear lookup failed', error);
  }

  try {
    if (vehicleIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT wt_id, vehicle_name, subgroup_name, base, control_modifier, speed, occupancy, hp, weight, price
          FROM wcc_item_vehicles_v
          WHERE lang = $1 AND wt_id = ANY($2::text[])
        `,
        [lang, vehicleIds],
      );
      rows.forEach((r: any) => vehiclesById.set(r.wt_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf vehicle lookup failed', error);
  }

  try {
    if (magicSpellLikeIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT ms_id, spell_name, level, element, stamina_cast, stamina_keeping, damage, distance, zone_size, form, effect_time, effect, sort_key, type
          FROM wcc_magic_spells_v
          WHERE lang = $1 AND ms_id = ANY($2::text[])
        `,
        [lang, magicSpellLikeIds],
      );
      rows.forEach((r: any) => magicSpellsById.set(r.ms_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf spells/signs lookup failed', error);
  }

  try {
    if (magicInvocationIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT ms_id, invocation_name, level, cult_or_circle, stamina_cast, stamina_keeping, damage, distance, zone_size, form, effect_time, effect, type
          FROM wcc_magic_invocations_v
          WHERE lang = $1 AND ms_id = ANY($2::text[])
        `,
        [lang, magicInvocationIds],
      );
      rows.forEach((r: any) => magicInvocationsById.set(r.ms_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf invocations lookup failed', error);
  }

  try {
    if (ritualIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT ms_id, ritual_name, level, dc, preparing_time, ingredients, zone_size, stamina_cast, stamina_keeping, effect_time, form, effect, effect_tpl, how_to_remove, sort_key
          FROM wcc_magic_rituals_v
          WHERE lang = $1 AND ms_id = ANY($2::text[])
        `,
        [lang, ritualIds],
      );
      rows.forEach((r: any) => magicRitualsById.set(r.ms_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf rituals lookup failed', error);
  }

  try {
    if (hexIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT ms_id, hex_name, level, stamina_cast, effect, remove_instructions, remove_components, tooltip, sort_key
          FROM wcc_magic_hexes_v
          WHERE lang = $1 AND ms_id = ANY($2::text[])
        `,
        [lang, hexIds],
      );
      rows.forEach((r: any) => magicHexesById.set(r.ms_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf hexes lookup failed', error);
  }

  try {
    if (giftIds.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT mg_id, group_name, gift_name, dc, vigor_cost, action_cost, description, sort_key, is_major
          FROM wcc_magic_gifts_v
          WHERE lang = $1 AND mg_id = ANY($2::text[])
        `,
        [lang, giftIds],
      );
      rows.forEach((r: any) => giftsById.set(r.mg_id, r));
    }
  } catch (error) {
    console.error('[characters] pdf gifts lookup failed', error);
  }

  try {
    const blueprintItemIds: string[] = [];
    for (const row of blueprintsById.values()) {
      const itemId = typeof row.item_id === 'string' ? row.item_id.trim() : '';
      if (itemId) blueprintItemIds.push(itemId);
    }

    const itemIdsForEffects = Array.from(
      new Set([...weaponIds, ...armorIds, ...upgradeIds, ...blueprintItemIds]),
    ).filter((id) => /^(W|A|U)/.test(id));

    if (itemIdsForEffects.length > 0) {
      const { rows } = await deps.db.query(
        `
          SELECT ite.item_id::text AS item_id,
                 ite.e_e_id::text AS effect_id,
                 ite.modifier AS modifier,
                 COALESCE(ie_lang.text, ie_en.text, '') AS name_tpl,
                 COALESCE(ide_lang.text, ide_en.text, '') AS desc_tpl,
                 COALESCE(iec_lang.text, iec_en.text, '') AS cond_tpl
          FROM wcc_item_to_effects ite
          LEFT JOIN wcc_item_effects e ON e.e_id = ite.e_e_id
          LEFT JOIN i18n_text ie_lang ON ie_lang.id = e.name_id AND ie_lang.lang = $1
          LEFT JOIN i18n_text ie_en ON ie_en.id = e.name_id AND ie_en.lang = 'en'
          LEFT JOIN i18n_text ide_lang ON ide_lang.id = e.description_id AND ide_lang.lang = $1
          LEFT JOIN i18n_text ide_en ON ide_en.id = e.description_id AND ide_en.lang = 'en'
          LEFT JOIN wcc_item_effect_conditions ec ON ec.ec_id = ite.ec_ec_id
          LEFT JOIN i18n_text iec_lang ON iec_lang.id = ec.description_id AND iec_lang.lang = $1
          LEFT JOIN i18n_text iec_en ON iec_en.id = ec.description_id AND iec_en.lang = 'en'
          WHERE ite.item_id = ANY($2::text[])
          ORDER BY ite.e_e_id ASC, ite.modifier ASC NULLS FIRST
        `,
        [lang, itemIdsForEffects],
      );

      const normalize = (v: string | null | undefined): string => String(v ?? '').trim();
      const replaceMod = (tpl: string, modifier: number | null): string => {
        const mod = modifier === null || modifier === undefined ? '' : String(modifier);
        return tpl.replaceAll('<mod>', mod);
      };
      const toSortNumber = (effectId: string): number => {
        const m = /^E(\d+)$/.exec(effectId.trim());
        if (!m) return Number.POSITIVE_INFINITY;
        const n = Number(m[1]);
        return Number.isFinite(n) ? n : Number.POSITIVE_INFINITY;
      };

      const byKey = new Map<string, { effectId: string; modifier: number | null; row: { name: string; value: string } }>();
      for (const row of rows as any[]) {
        const effectId = normalize(row.effect_id);
        const nameTpl = normalize(row.name_tpl);
        if (!effectId && !nameTpl) continue;
        const cond = replaceMod(normalize(row.cond_tpl), row.modifier).trim();
        const nameBase = replaceMod(nameTpl || effectId, row.modifier).trim();
        const name = cond ? `${nameBase} [${cond}]` : nameBase;
        const value = replaceMod(normalize(row.desc_tpl), row.modifier).trim();
        const key = `${effectId}|${row.modifier ?? ''}|${cond}`;
        if (byKey.has(key)) continue;
        byKey.set(key, {
          effectId,
          modifier: row.modifier ?? null,
          row: { name, value },
        });
      }

      const sorted = Array.from(byKey.values()).sort((a, b) => {
        const an = toSortNumber(a.effectId);
        const bn = toSortNumber(b.effectId);
        if (an !== bn) return an - bn;
        const am = a.modifier ?? Number.NEGATIVE_INFINITY;
        const bm = b.modifier ?? Number.NEGATIVE_INFINITY;
        if (am !== bm) return am - bm;
        return a.row.name.localeCompare(b.row.name, undefined, { sensitivity: 'base' });
      });
      itemEffectsGlossary.push(...sorted.map((x) => x.row));
    }
  } catch (error) {
    console.error('[characters] pdf item effects lookup failed', error);
  }

  deps.patchResolvedGearFromDbViews({
    rawCharacter,
    resolvedCharacter,
    weaponsById,
    armorsById,
    potionsById,
    recipesById,
    blueprintsById,
    ingredientsById,
    generalGearById,
    vehiclesById,
    magicSpellsById,
    magicInvocationsById,
    magicRitualsById,
    magicHexesById,
    giftsById,
  });

  const skillsCatalog = await deps.getSkillsCatalog({ lang }).catch(() => ({ skills: [] as Array<{ id: string; param: string | null; name: string }> }));
  const skillsCatalogById = new Map(
    (Array.isArray(skillsCatalog.skills) ? skillsCatalog.skills : []).map((s) => [s.id, { param: s.param, name: s.name }] as const),
  );

  let avatarBuffer: Buffer | undefined = parseAvatarDataUrlBuffer(rawCharacter.avatarDataUrl);
  if (!avatarBuffer && avatarUrl) {
    try {
      const avatarRes = await deps.loadAvatarFromStorage(avatarUrl);
      if (avatarRes) {
        avatarBuffer = avatarRes.data;
      }
    } catch (error) {
      console.warn('[characters] pdf avatar load failed', error);
    }
  }

  const pdfBuffer = await deps.generateCharacterPdfBuffer({
    rawCharacter: rawCharacterForPdf,
    resolvedCharacter,
    lang,
    skillsCatalogById,
    itemEffectsGlossary,
    avatarBuffer,
  });

  const candidateName =
    explicitName ??
    (typeof rawCharacter.name === 'string'
      ? rawCharacter.name
      : typeof rawCharacter.characterName === 'string'
        ? rawCharacter.characterName
        : typeof rawCharacter.fullName === 'string'
          ? rawCharacter.fullName
          : null);

  const fileName = `${deps.safeFileNameBase(candidateName, 'character')}-sheet.pdf`;
  return { pdfBuffer, fileName };
}
