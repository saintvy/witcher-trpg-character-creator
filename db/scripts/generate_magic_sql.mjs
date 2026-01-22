import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

/**
 * Postgres ck_id(src text) implementation (see db/sql/wcc_ddl_schema.sql)
 * namespace UUID is treated as plain text concatenated with src, then md5.
 */
function ckId(src) {
  const ns = '12345678-9098-7654-3212-345678909876';
  const m = crypto.createHash('md5').update(ns + src, 'utf8').digest('hex');
  return `${m.slice(0, 8)}-${m.slice(8, 12)}-${m.slice(12, 16)}-${m.slice(16, 20)}-${m.slice(20, 32)}`;
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function dollarQuote(text) {
  const s = text ?? '';
  // choose a tag that does not appear in the content
  const candidates = ['$$', '$magic$', '$wcc$', '$txt$'];
  for (const tag of candidates) {
    const end = tag;
    if (!s.includes(end)) return `${tag}${s}${tag}`;
  }
  // fallback: random tag
  const rnd = crypto.randomBytes(4).toString('hex');
  const tag = `$dq_${rnd}$`;
  return `${tag}${s}${tag}`;
}

function normalizeNewlines(s) {
  return (s ?? '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

function splitRecordsByMsId(tsvText) {
  const lines = normalizeNewlines(tsvText).split('\n');
  if (lines.length === 0) return { header: '', records: [] };
  const header = lines[0] ?? '';

  const records = [];
  let cur = null;

  const isStart = (line) => /^MS\d{3}\t/.test(line);

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i] ?? '';
    if (isStart(line)) {
      if (cur) records.push(cur);
      cur = line;
    } else if (cur) {
      // preserve embedded newlines inside a field
      cur += '\n' + line;
    } else {
      // skip any garbage before first record
    }
  }
  if (cur) records.push(cur);
  return { header, records };
}

function parseTsvRecord(block, headerColumns) {
  const parts = block.split('\t');
  if (parts.length > headerColumns.length) {
    const head = parts.slice(0, headerColumns.length - 1);
    const tail = parts.slice(headerColumns.length - 1).join('\t');
    return [...head, tail];
  }
  if (parts.length < headerColumns.length) {
    return [...parts, ...Array(headerColumns.length - parts.length).fill('')];
  }
  return parts;
}

const FORM_KEY_BY_RAW = new Map([
  ['Прямая', 'magic.form.direct'],
  ['Прямая (Отскок)', 'magic.form.direct_bounce'],
  ['На себя', 'magic.form.self'],
  ['Зона центрированная', 'magic.form.zone_centered'],
  ['Зона (круг)', 'magic.form.zone_circle'],
  ['Зона (круг вокруг себя)', 'magic.form.zone_circle_around'],
  ['Зона (конус)', 'magic.form.zone_cone'],
  ['Зона (квадрат)', 'magic.form.zone_square'],
  ['Зона (куб)', 'magic.form.zone_cube'],
]);

function buildNameMaps(repoRoot) {
  const ingredientsSql = fs.readFileSync(path.join(repoRoot, 'db/sql/items/011_wcc_item_ingredients.sql'), 'utf8');
  const gearSql = fs.readFileSync(path.join(repoRoot, 'db/sql/items/009_wcc_item_general_gear.sql'), 'utf8');
  const vehiclesSql = fs.readFileSync(path.join(repoRoot, 'db/sql/items/012_wcc_item_vehicles.sql'), 'utf8');

  // Ingredients tuples: ('RU', 'EN', 'I123', ...)
  const ingredientByRu = new Map();
  for (const m of ingredientsSql.matchAll(/\(\s*'((?:''|[^'])*)'\s*,\s*'((?:''|[^'])*)'\s*,\s*'(I\d{3})'\s*,/g)) {
    const ru = m[1].replace(/''/g, "'");
    const iId = m[3];
    ingredientByRu.set(ru, iId);
  }

  // Vehicles tuples: ('WT009','Боевой конь','War Horse', ...)
  const vehicleByRu = new Map();
  for (const m of vehiclesSql.matchAll(/\(\s*'(WT\d{3})'\s*,\s*'((?:''|[^'])*)'\s*,\s*'((?:''|[^'])*)'\s*,/g)) {
    const wtId = m[1];
    const ru = m[2].replace(/''/g, "'");
    vehicleByRu.set(ru, wtId);
  }

  // General gear tuples: ('T078', ..., 'Мелок','Chalk', ...)
  // Capture t_id + name_ru + name_en by column position in 009_wcc_item_general_gear.sql raw_data
  const gearByRu = new Map();
  for (const m of gearSql.matchAll(
    /\(\s*'(T\d{3})'\s*,\s*'[^']*'\s*,\s*'((?:''|[^'])*)'\s*,\s*'((?:''|[^'])*)'\s*,\s*'((?:''|[^'])*)'\s*,\s*'((?:''|[^'])*)'\s*,/g,
  )) {
    const tId = m[1];
    const nameRu = m[4].replace(/''/g, "'");
    gearByRu.set(nameRu, tId);
  }

  return { ingredientByRu, gearByRu, vehicleByRu };
}

function parseComponentsList(raw, { ingredientByRu, gearByRu, vehicleByRu }) {
  const cleaned = (raw ?? '')
    .replace(/<--------/g, '')
    .replace(/<ИЛИ/g, 'ИЛИ')
    .replace(/\s+и\s+/g, ', ')
    .trim();
  if (!cleaned) return null;

  const parts = cleaned.split(',').map((s) => s.trim()).filter(Boolean);
  const items = [];

  const specialKeyByName = new Map([
    ['Головная броня', 'upgrades.target.head'],
    ['Корпусная броня', 'upgrades.target.torso'],
    ['Ножная броня', 'upgrades.target.legs'],
  ]);

  for (const p of parts) {
    if (p === 'ИЛИ') {
      items.push({ id: ckId('magic.components.or'), qty: null });
      continue;
    }

    // Hex-style qty: [1] Item
    const mSquare = p.match(/^\[(\d+)]\s*(.+)$/);
    let qty = null;
    let name = p;
    if (mSquare) {
      qty = mSquare[1];
      name = mSquare[2].trim();
    }

    // Parentheses qty: Name (1) or Name (50 крон)
    const mParen = name.match(/^(.*)\(([^()]*)\)\s*$/);
    if (mParen) {
      name = mParen[1].trim();
      const q = mParen[2].trim();
      if (q) qty = q;
    }

    // Normalize "[на 40 крон] Алкоголь" -> our technical ingredient name
    if (/^\[на\s*40\s*крон]\s*Алкоголь$/i.test(p.trim())) {
      name = 'Алкоголь (на 40 крон)';
    }

    // Normalize "Бутылка спиртного" to technical ingredient (we added it explicitly)
    if (name === 'Бутылка спиртного') {
      // keep name as-is; it exists as custom ingredient I272
    }

    const dictKey = specialKeyByName.get(name);
    if (dictKey) {
      items.push({ id: ckId(dictKey), qty });
      continue;
    }

    const iId = ingredientByRu.get(name);
    if (iId) {
      items.push({ id: ckId(`witcher_cc.items.ingredient.name.${iId}`), qty });
      continue;
    }
    const tId = gearByRu.get(name);
    if (tId) {
      items.push({ id: ckId(`witcher_cc.items.general_gear.name.${tId}`), qty });
      continue;
    }
    const wtId = vehicleByRu.get(name);
    if (wtId) {
      items.push({ id: ckId(`witcher_cc.items.vehicle.name.${wtId}`), qty });
      continue;
    }

    // Unknown component name: store as technical ingredient id (by deterministic key)
    // NOTE: this requires the ingredient to exist in 011_wcc_item_ingredients.sql. We'll still emit a stable id.
    items.push({ id: ckId(`custom.technical.${name}`), qty });
  }

  return items;
}

function toJsonbLiteral(arr) {
  if (!arr) return 'NULL';
  // Store qty as string or null; id as uuid string
  const json = JSON.stringify(arr.map((x) => ({ id: x.id, qty: x.qty })));
  return `${dollarQuote(json)}::jsonb`;
}

function cleanTextForSql(t) {
  // Keep as-is; SQL will strip HTML. We just normalize line endings.
  return normalizeNewlines(t ?? '').trim();
}

function writeFile(targetPath, content) {
  ensureDir(path.dirname(targetPath));
  fs.writeFileSync(targetPath, content, 'utf8');
}

function generateSpellsSql(repoRoot, outPath, tsvPath) {
  const { header, records } = splitRecordsByMsId(fs.readFileSync(tsvPath, 'utf8'));
  const headerCols = header.split('\t').map((s) => s.trim());
  const rows = records.map((r) => {
    const cols = parseTsvRecord(r, headerCols);
    const obj = Object.fromEntries(headerCols.map((h, i) => [h, cols[i] ?? '']));
    // Normalize fields
    const formKey = FORM_KEY_BY_RAW.get((obj.form ?? '').trim()) ?? '';
    return {
      ms_id: obj.ms_id,
      dlc_dlc_id: obj.dlc_dlc_id,
      level_key: obj.level,
      element_key: obj.element,
      name_ru: obj.name_ru,
      name_en: obj.name_en,
      effect_1: cleanTextForSql(obj.effect_1),
      form_key: formKey,
      distance: (obj.distance ?? '').trim(),
      zone_size: (obj.zone_size ?? '').trim(),
      stamina_cast: (obj.vigor_cast ?? '').trim(),
      stamina_keeping: (obj.vigor_keeping ?? '').trim(),
      damage: (obj.damage ?? '').trim(),
      effect_time_value: (obj.effect_time_value ?? '').trim(),
      effect_time_unit: (obj.effect_time_unit ?? '').trim(),
      defense_1: (obj.defense_1 ?? '').trim(),
      defense_2: (obj.defense_2 ?? '').trim(),
      defense_3: (obj.defense_3 ?? '').trim(),
    };
  });

  const valuesLines = rows.map((x) => {
    const cols = [
      `'${x.ms_id}'`,
      `'${x.dlc_dlc_id}'`,
      `'${x.level_key}'`,
      `'${x.element_key}'`,
      dollarQuote(x.name_ru),
      dollarQuote(x.name_en),
      dollarQuote(x.effect_1),
      `'${x.form_key}'`,
      dollarQuote(x.distance),
      dollarQuote(x.zone_size),
      dollarQuote(x.stamina_cast),
      dollarQuote(x.stamina_keeping),
      dollarQuote(x.damage),
      dollarQuote(x.effect_time_value),
      `'${x.effect_time_unit}'`,
      dollarQuote(x.defense_1),
      dollarQuote(x.defense_2),
      dollarQuote(x.defense_3),
    ];
    return `  (${cols.join(', ')})`;
  });

  const sql = `\\echo '017_wcc_magic_spells.sql'
-- Magic spells (and Witcher Signs) from temp TSV

CREATE TABLE IF NOT EXISTS wcc_magic_spells (
  ms_id              varchar(10) PRIMARY KEY,  -- e.g. 'MS001'
  dlc_dlc_id         varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  level_id           uuid NULL,                -- ck_id('level.*')
  element_id         uuid NULL,                -- ck_id('element.*')
  form_id            uuid NULL,                -- ck_id('magic.form.*')
  effect_time_unit_id uuid NULL,               -- ck_id('time.unit.*')

  name_id            uuid NOT NULL,            -- ck_id('witcher_cc.magic.spell.name.'||ms_id)
  effect_id          uuid NOT NULL,            -- ck_id('witcher_cc.magic.spell.effect.'||ms_id)

  distance           text NULL,
  zone_size          text NULL,
  stamina_cast       text NULL,
  stamina_keeping    text NULL,
  damage             text NULL,
  effect_time_value  text NULL,

  defense_ids        uuid[] NULL               -- array of ck_id('skill.*') / ck_id('parameter.*') used for defense
);

WITH raw_data (
  ms_id, dlc_dlc_id,
  level_key, element_key,
  name_ru, name_en,
  effect_ru,
  form_key,
  distance, zone_size,
  stamina_cast, stamina_keeping,
  damage,
  effect_time_value, effect_time_unit_key,
  defense_1, defense_2, defense_3
) AS ( VALUES
${valuesLines.join(',\n')}
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- names
    SELECT ck_id('witcher_cc.magic.spell.name.'||rd.ms_id),
           'magic',
           'spell_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.spell.name.'||rd.ms_id),
           'magic',
           'spell_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    -- effects (HTML stripped at insert time)
    SELECT ck_id('witcher_cc.magic.spell.effect.'||rd.ms_id),
           'magic',
           'spell_effects',
           'ru',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.spell.effect.'||rd.ms_id),
           'magic',
           'spell_effects',
           'en',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO wcc_magic_spells (
  ms_id, dlc_dlc_id,
  level_id, element_id, form_id,
  name_id, effect_id,
  distance, zone_size,
  stamina_cast, stamina_keeping,
  damage,
  effect_time_value, effect_time_unit_id,
  defense_ids
)
SELECT rd.ms_id
     , rd.dlc_dlc_id
     , CASE WHEN nullif(rd.level_key,'') IS NOT NULL THEN ck_id(rd.level_key) ELSE NULL END AS level_id
     , CASE WHEN nullif(rd.element_key,'') IS NOT NULL THEN ck_id(rd.element_key) ELSE NULL END AS element_id
     , CASE WHEN nullif(rd.form_key,'') IS NOT NULL THEN ck_id(rd.form_key) ELSE NULL END AS form_id
     , ck_id('witcher_cc.magic.spell.name.'||rd.ms_id) AS name_id
     , ck_id('witcher_cc.magic.spell.effect.'||rd.ms_id) AS effect_id
     , nullif(rd.distance,'')
     , nullif(rd.zone_size,'')
     , nullif(rd.stamina_cast,'')
     , nullif(rd.stamina_keeping,'')
     , nullif(rd.damage,'')
     , nullif(rd.effect_time_value,'')
     , CASE
         WHEN rd.effect_time_unit_key LIKE 'time.unit.%' THEN ck_id(rd.effect_time_unit_key)
         ELSE NULL
       END AS effect_time_unit_id
     , ARRAY_REMOVE(ARRAY[
         CASE btrim(rd.defense_1)
           WHEN 'Уклонение' THEN ck_id('skill.dodge')
           WHEN 'Уклонение/Изворотливость' THEN ck_id('skill.dodge_escape')
           WHEN 'Атлетика' THEN ck_id('skill.athletics')
           WHEN 'Блокирование' THEN ck_id('skill.blocking')
           WHEN 'Сопротивление магии' THEN ck_id('skill.resist_magic')
           WHEN 'Сопротивление убеждению' THEN ck_id('skill.resist_coercion')
           WHEN 'Сотворение заклинаний' THEN ck_id('skill.spell_casting')
           WHEN 'СЛ от ведущего' THEN ck_id('skill.gm_dc')
           ELSE NULL
         END,
         CASE btrim(rd.defense_2)
           WHEN 'Уклонение' THEN ck_id('skill.dodge')
           WHEN 'Уклонение/Изворотливость' THEN ck_id('skill.dodge_escape')
           WHEN 'Атлетика' THEN ck_id('skill.athletics')
           WHEN 'Блокирование' THEN ck_id('skill.blocking')
           WHEN 'Сопротивление магии' THEN ck_id('skill.resist_magic')
           WHEN 'Сопротивление убеждению' THEN ck_id('skill.resist_coercion')
           WHEN 'Сотворение заклинаний' THEN ck_id('skill.spell_casting')
           WHEN 'СЛ от ведущего' THEN ck_id('skill.gm_dc')
           ELSE NULL
         END,
         CASE btrim(rd.defense_3)
           WHEN 'Уклонение' THEN ck_id('skill.dodge')
           WHEN 'Уклонение/Изворотливость' THEN ck_id('skill.dodge_escape')
           WHEN 'Атлетика' THEN ck_id('skill.athletics')
           WHEN 'Блокирование' THEN ck_id('skill.blocking')
           WHEN 'Сопротивление магии' THEN ck_id('skill.resist_magic')
           WHEN 'Сопротивление убеждению' THEN ck_id('skill.resist_coercion')
           WHEN 'Сотворение заклинаний' THEN ck_id('skill.spell_casting')
           WHEN 'СЛ от ведущего' THEN ck_id('skill.gm_dc')
           ELSE NULL
         END
       ], NULL)::uuid[] AS defense_ids
  FROM raw_data rd
ON CONFLICT (ms_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  level_id = EXCLUDED.level_id,
  element_id = EXCLUDED.element_id,
  form_id = EXCLUDED.form_id,
  effect_time_unit_id = EXCLUDED.effect_time_unit_id,
  name_id = EXCLUDED.name_id,
  effect_id = EXCLUDED.effect_id,
  distance = EXCLUDED.distance,
  zone_size = EXCLUDED.zone_size,
  stamina_cast = EXCLUDED.stamina_cast,
  stamina_keeping = EXCLUDED.stamina_keeping,
  damage = EXCLUDED.damage,
  effect_time_value = EXCLUDED.effect_time_value,
  defense_ids = EXCLUDED.defense_ids;
`;

  writeFile(outPath, sql);
}

function generateHexesSql(repoRoot, outPath, tsvPath, maps) {
  const { header, records } = splitRecordsByMsId(fs.readFileSync(tsvPath, 'utf8'));
  const headerCols = header.split('\t').map((s) => s.trim());

  const rows = records.map((r) => {
    const cols = parseTsvRecord(r, headerCols);
    const obj = Object.fromEntries(headerCols.map((h, i) => [h, cols[i] ?? '']));
    const components = parseComponentsList(obj.remove_components, maps);
    return {
      ms_id: obj.ms_id,
      dlc_dlc_id: obj.dlc_dlc_id,
      level_key: obj.level,
      name_ru: obj.name_ru,
      name_en: obj.name_en,
      effect_ru: cleanTextForSql(obj.effect),
      remove_instructions_ru: cleanTextForSql(obj.remove_instructions),
      remove_components_json: toJsonbLiteral(components),
      stamina_cast: (obj.vigor_cast ?? '').trim(),
    };
  });

  const valuesLines = rows.map((x) => {
    const cols = [
      `'${x.ms_id}'`,
      `'${x.dlc_dlc_id}'`,
      `'${x.level_key}'`,
      dollarQuote(x.name_ru),
      dollarQuote(x.name_en),
      dollarQuote(x.effect_ru),
      x.remove_components_json,
      dollarQuote(x.remove_instructions_ru),
      dollarQuote(x.stamina_cast),
    ];
    return `  (${cols.join(', ')})`;
  });

  const sql = `\\echo '018_wcc_magic_hexes.sql'
-- Magic hexes from temp TSV

CREATE TABLE IF NOT EXISTS wcc_magic_hexes (
  ms_id              varchar(10) PRIMARY KEY,  -- e.g. 'MS119'
  dlc_dlc_id         varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  level_id           uuid NULL,                -- ck_id('level.*')

  name_id            uuid NOT NULL,            -- ck_id('witcher_cc.magic.hex.name.'||ms_id)
  effect_id          uuid NOT NULL,            -- ck_id('witcher_cc.magic.hex.effect.'||ms_id)
  remove_instructions_id uuid NOT NULL,        -- ck_id('witcher_cc.magic.hex.remove_instructions.'||ms_id)

  remove_components  jsonb NULL,               -- [{"id":"<uuid>","qty":"<text|null>"}, ...]
  stamina_cast       text NULL
);

WITH raw_data (
  ms_id, dlc_dlc_id,
  level_key,
  name_ru, name_en,
  effect_ru,
  remove_components,
  remove_instructions_ru,
  stamina_cast
) AS ( VALUES
${valuesLines.join(',\n')}
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.magic.hex.name.'||rd.ms_id),
           'magic',
           'hex_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.name.'||rd.ms_id),
           'magic',
           'hex_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.effect.'||rd.ms_id),
           'magic',
           'hex_effects',
           'ru',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.effect.'||rd.ms_id),
           'magic',
           'hex_effects',
           'en',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.remove_instructions.'||rd.ms_id),
           'magic',
           'hex_remove_instructions',
           'ru',
           regexp_replace(replace(replace(rd.remove_instructions_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.remove_instructions_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.remove_instructions.'||rd.ms_id),
           'magic',
           'hex_remove_instructions',
           'en',
           regexp_replace(replace(replace(rd.remove_instructions_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.remove_instructions_ru,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO wcc_magic_hexes (
  ms_id, dlc_dlc_id,
  level_id,
  name_id, effect_id, remove_instructions_id,
  remove_components,
  stamina_cast
)
SELECT rd.ms_id
     , rd.dlc_dlc_id
     , CASE WHEN nullif(rd.level_key,'') IS NOT NULL THEN ck_id(rd.level_key) ELSE NULL END AS level_id
     , ck_id('witcher_cc.magic.hex.name.'||rd.ms_id) AS name_id
     , ck_id('witcher_cc.magic.hex.effect.'||rd.ms_id) AS effect_id
     , ck_id('witcher_cc.magic.hex.remove_instructions.'||rd.ms_id) AS remove_instructions_id
     , rd.remove_components
     , nullif(rd.stamina_cast,'')
  FROM raw_data rd
ON CONFLICT (ms_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  level_id = EXCLUDED.level_id,
  name_id = EXCLUDED.name_id,
  effect_id = EXCLUDED.effect_id,
  remove_instructions_id = EXCLUDED.remove_instructions_id,
  remove_components = EXCLUDED.remove_components,
  stamina_cast = EXCLUDED.stamina_cast;
`;

  writeFile(outPath, sql);
}

function generateInvocationsSql(repoRoot, outPath, tsvPath) {
  const { header, records } = splitRecordsByMsId(fs.readFileSync(tsvPath, 'utf8'));
  const headerCols = header.split('\t').map((s) => s.trim());

  const rows = records.map((r) => {
    const cols = parseTsvRecord(r, headerCols);
    const obj = Object.fromEntries(headerCols.map((h, i) => [h, cols[i] ?? '']));
    const formKey = FORM_KEY_BY_RAW.get((obj.form ?? '').trim()) ?? '';
    const effect1 = cleanTextForSql(obj.effect_1);
    const effect2 = cleanTextForSql(obj.effect_2);
    const effect = effect2 ? `${effect1}\n${effect2}`.trim() : effect1;
    return {
      ms_id: obj.ms_id,
      dlc_dlc_id: obj.dlc_dlc_id,
      magic_type_key: obj.magic_type,
      level_key: obj.level,
      cult_ru: (obj.cult_or_circle_ru ?? '').trim(),
      cult_en: (obj.cult_or_circle_en ?? '').trim(),
      name_ru: obj.name_ru,
      name_en: obj.name_en,
      effect_ru: effect,
      form_key: formKey,
      distance: (obj.distance ?? '').trim(),
      zone_size: (obj.zone_size ?? '').trim(),
      stamina_cast: (obj.vigor_cast ?? '').trim(),
      stamina_keeping: (obj.vigor_keeping ?? '').trim(),
      damage: (obj.damage ?? '').trim(),
      effect_time_value: (obj.effect_time_value ?? '').trim(),
      effect_time_unit: (obj.effect_time_unit ?? '').trim(),
      defense_1: (obj.defence_1 ?? '').trim(),
      defense_2: (obj.defence_2 ?? '').trim(),
    };
  });

  const valuesLines = rows.map((x) => {
    const cols = [
      `'${x.ms_id}'`,
      `'${x.dlc_dlc_id}'`,
      `'${x.magic_type_key}'`,
      `'${x.level_key}'`,
      dollarQuote(x.cult_ru),
      dollarQuote(x.cult_en),
      dollarQuote(x.name_ru),
      dollarQuote(x.name_en),
      dollarQuote(x.effect_ru),
      `'${x.form_key}'`,
      dollarQuote(x.distance),
      dollarQuote(x.zone_size),
      dollarQuote(x.stamina_cast),
      dollarQuote(x.stamina_keeping),
      dollarQuote(x.damage),
      dollarQuote(x.effect_time_value),
      `'${x.effect_time_unit}'`,
      dollarQuote(x.defense_1),
      dollarQuote(x.defense_2),
    ];
    return `  (${cols.join(', ')})`;
  });

  const sql = `\\echo '019_wcc_magic_invocations.sql'
-- Magic invocations (druid & priest) from temp TSV

CREATE TABLE IF NOT EXISTS wcc_magic_invocations (
  ms_id               varchar(10) PRIMARY KEY,  -- e.g. 'MS066'
  dlc_dlc_id          varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  magic_type_id       uuid NOT NULL,            -- ck_id('magic.gruid_invocations' | 'magic.priest_invocations')
  level_id            uuid NULL,                -- ck_id('level.*')
  form_id             uuid NULL,                -- ck_id('magic.form.*')
  effect_time_unit_id uuid NULL,                -- ck_id('time.unit.*')

  cult_or_circle_id   uuid NULL,                -- ck_id('witcher_cc.magic.invocation.cult_or_circle.'||ms_id)
  name_id             uuid NOT NULL,            -- ck_id('witcher_cc.magic.invocation.name.'||ms_id)
  effect_id           uuid NOT NULL,            -- ck_id('witcher_cc.magic.invocation.effect.'||ms_id)

  distance            text NULL,
  zone_size           text NULL,
  stamina_cast        text NULL,
  stamina_keeping     text NULL,
  damage              text NULL,
  effect_time_value   text NULL,

  defense_ids         uuid[] NULL
);

WITH raw_data (
  ms_id, dlc_dlc_id,
  magic_type_key, level_key,
  cult_ru, cult_en,
  name_ru, name_en,
  effect_ru,
  form_key,
  distance, zone_size,
  stamina_cast, stamina_keeping,
  damage,
  effect_time_value, effect_time_unit_key,
  defense_1, defense_2
) AS ( VALUES
${valuesLines.join(',\n')}
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- cult/circle
    SELECT ck_id('witcher_cc.magic.invocation.cult_or_circle.'||rd.ms_id),
           'magic',
           'invocation_cults',
           'ru',
           rd.cult_ru
      FROM raw_data rd
     WHERE nullif(rd.cult_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.invocation.cult_or_circle.'||rd.ms_id),
           'magic',
           'invocation_cults',
           'en',
           rd.cult_en
      FROM raw_data rd
     WHERE nullif(rd.cult_en,'') IS NOT NULL
    UNION ALL
    -- names
    SELECT ck_id('witcher_cc.magic.invocation.name.'||rd.ms_id),
           'magic',
           'invocation_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.invocation.name.'||rd.ms_id),
           'magic',
           'invocation_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    -- effects (effect_1 + effect_2 already merged; HTML stripped)
    SELECT ck_id('witcher_cc.magic.invocation.effect.'||rd.ms_id),
           'magic',
           'invocation_effects',
           'ru',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.invocation.effect.'||rd.ms_id),
           'magic',
           'invocation_effects',
           'en',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO wcc_magic_invocations (
  ms_id, dlc_dlc_id,
  magic_type_id,
  level_id, form_id, effect_time_unit_id,
  cult_or_circle_id,
  name_id, effect_id,
  distance, zone_size,
  stamina_cast, stamina_keeping,
  damage,
  effect_time_value,
  defense_ids
)
SELECT rd.ms_id
     , rd.dlc_dlc_id
     , ck_id(rd.magic_type_key) AS magic_type_id
     , CASE WHEN nullif(rd.level_key,'') IS NOT NULL THEN ck_id(rd.level_key) ELSE NULL END AS level_id
     , CASE WHEN nullif(rd.form_key,'') IS NOT NULL THEN ck_id(rd.form_key) ELSE NULL END AS form_id
     , CASE
         WHEN rd.effect_time_unit_key LIKE 'time.unit.%' THEN ck_id(rd.effect_time_unit_key)
         ELSE NULL
       END AS effect_time_unit_id
     , CASE WHEN nullif(rd.cult_ru,'') IS NOT NULL OR nullif(rd.cult_en,'') IS NOT NULL THEN ck_id('witcher_cc.magic.invocation.cult_or_circle.'||rd.ms_id) ELSE NULL END AS cult_or_circle_id
     , ck_id('witcher_cc.magic.invocation.name.'||rd.ms_id) AS name_id
     , ck_id('witcher_cc.magic.invocation.effect.'||rd.ms_id) AS effect_id
     , nullif(rd.distance,'')
     , nullif(rd.zone_size,'')
     , nullif(rd.stamina_cast,'')
     , nullif(rd.stamina_keeping,'')
     , nullif(rd.damage,'')
     , nullif(rd.effect_time_value,'')
     , ARRAY_REMOVE(ARRAY[
         CASE btrim(rd.defense_1)
           WHEN 'Уклонение' THEN ck_id('skill.dodge')
           WHEN 'Атлетика' THEN ck_id('skill.athletics')
           WHEN 'Блокирование' THEN ck_id('skill.blocking')
           WHEN 'Сопротивление магии' THEN ck_id('skill.resist_magic')
           WHEN 'Сопротивление убеждению' THEN ck_id('skill.resist_coercion')
           WHEN 'СЛ от ведущего' THEN ck_id('skill.gm_dc')
           WHEN 'Воля*3' THEN ck_id('parameter.will_x3')
           ELSE NULL
         END,
         CASE btrim(rd.defense_2)
           WHEN 'Уклонение' THEN ck_id('skill.dodge')
           WHEN 'Атлетика' THEN ck_id('skill.athletics')
           WHEN 'Блокирование' THEN ck_id('skill.blocking')
           WHEN 'Сопротивление магии' THEN ck_id('skill.resist_magic')
           WHEN 'Сопротивление убеждению' THEN ck_id('skill.resist_coercion')
           WHEN 'СЛ от ведущего' THEN ck_id('skill.gm_dc')
           WHEN 'Воля*3' THEN ck_id('parameter.will_x3')
           ELSE NULL
         END
       ], NULL)::uuid[] AS defense_ids
  FROM raw_data rd
ON CONFLICT (ms_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  magic_type_id = EXCLUDED.magic_type_id,
  level_id = EXCLUDED.level_id,
  form_id = EXCLUDED.form_id,
  effect_time_unit_id = EXCLUDED.effect_time_unit_id,
  cult_or_circle_id = EXCLUDED.cult_or_circle_id,
  name_id = EXCLUDED.name_id,
  effect_id = EXCLUDED.effect_id,
  distance = EXCLUDED.distance,
  zone_size = EXCLUDED.zone_size,
  stamina_cast = EXCLUDED.stamina_cast,
  stamina_keeping = EXCLUDED.stamina_keeping,
  damage = EXCLUDED.damage,
  effect_time_value = EXCLUDED.effect_time_value,
  defense_ids = EXCLUDED.defense_ids;
`;

  writeFile(outPath, sql);
}

function generateRitualsSql(repoRoot, outPath, tsvPath, maps) {
  const { header, records } = splitRecordsByMsId(fs.readFileSync(tsvPath, 'utf8'));
  const headerCols = header.split('\t').map((s) => s.trim());

  const rows = records.map((r) => {
    const cols = parseTsvRecord(r, headerCols);
    const obj = Object.fromEntries(headerCols.map((h, i) => [h, cols[i] ?? '']));
    const formKey = FORM_KEY_BY_RAW.get((obj.form ?? '').trim()) ?? '';
    const effect1 = cleanTextForSql(obj.effect_1);
    const effect2 = cleanTextForSql(obj.effect_2);
    const effect = effect2 ? `${effect1}\n${effect2}`.trim() : effect1;
    const components = parseComponentsList(obj.ingredients, maps);
    return {
      ms_id: obj.ms_id,
      dlc_dlc_id: obj.dlc_dlc_id,
      level_key: obj.level,
      name_ru: obj.name_ru,
      name_en: obj.name_en,
      effect_ru: effect,
      how_to_remove_ru: cleanTextForSql(obj.how_to_remove),
      dc: (obj.DC ?? '').trim(),
      preparing_time_value: (obj.preparing_time_value ?? '').trim(),
      ingredients_json: toJsonbLiteral(components),
      form_key: formKey,
      zone_size: (obj.zone_size ?? '').trim(),
      stamina_cast: (obj.vigor_cast ?? '').trim(),
      stamina_keeping: (obj.vigor_keeping ?? '').trim(),
      effect_time_value: (obj.effect_time_value ?? '').trim(),
      effect_time_unit: (obj.effect_time_unit ?? '').trim(),
    };
  });

  const valuesLines = rows.map((x) => {
    const cols = [
      `'${x.ms_id}'`,
      `'${x.dlc_dlc_id}'`,
      `'${x.level_key}'`,
      dollarQuote(x.name_ru),
      dollarQuote(x.name_en),
      dollarQuote(x.effect_ru),
      dollarQuote(x.how_to_remove_ru),
      dollarQuote(x.dc),
      dollarQuote(x.preparing_time_value),
      x.ingredients_json,
      `'${x.form_key}'`,
      dollarQuote(x.zone_size),
      dollarQuote(x.stamina_cast),
      dollarQuote(x.stamina_keeping),
      dollarQuote(x.effect_time_value),
      `'${x.effect_time_unit}'`,
    ];
    return `  (${cols.join(', ')})`;
  });

  const sql = `\\echo '020_wcc_magic_rituals.sql'
-- Magic rituals from temp TSV

CREATE TABLE IF NOT EXISTS wcc_magic_rituals (
  ms_id                 varchar(10) PRIMARY KEY,  -- e.g. 'MS104'
  dlc_dlc_id            varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  level_id              uuid NULL,                -- ck_id('level.*')
  form_id               uuid NULL,                -- ck_id('magic.form.*')
  effect_time_unit_id   uuid NULL,                -- ck_id('time.unit.*')
  preparing_time_unit_id uuid NOT NULL,           -- always time.unit.round (per rules)

  name_id               uuid NOT NULL,            -- ck_id('witcher_cc.magic.ritual.name.'||ms_id)
  effect_id             uuid NOT NULL,            -- ck_id('witcher_cc.magic.ritual.effect.'||ms_id)
  how_to_remove_id      uuid NULL,                -- ck_id('witcher_cc.magic.ritual.how_to_remove.'||ms_id)

  dc                    text NULL,
  preparing_time_value  integer NULL,
  ingredients           jsonb NULL,               -- [{"id":"<uuid>","qty":"<text|null>"}, ...]

  zone_size             text NULL,
  stamina_cast          text NULL,
  stamina_keeping       text NULL,
  effect_time_value     text NULL
);

WITH raw_data (
  ms_id, dlc_dlc_id,
  level_key,
  name_ru, name_en,
  effect_ru,
  how_to_remove_ru,
  dc,
  preparing_time_value,
  ingredients,
  form_key,
  zone_size,
  stamina_cast, stamina_keeping,
  effect_time_value, effect_time_unit_key
) AS ( VALUES
${valuesLines.join(',\n')}
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.magic.ritual.name.'||rd.ms_id),
           'magic',
           'ritual_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.name.'||rd.ms_id),
           'magic',
           'ritual_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.effect.'||rd.ms_id),
           'magic',
           'ritual_effects',
           'ru',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.effect.'||rd.ms_id),
           'magic',
           'ritual_effects',
           'en',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.how_to_remove.'||rd.ms_id),
           'magic',
           'ritual_how_to_remove',
           'ru',
           regexp_replace(replace(replace(rd.how_to_remove_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.how_to_remove_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.how_to_remove.'||rd.ms_id),
           'magic',
           'ritual_how_to_remove',
           'en',
           regexp_replace(replace(replace(rd.how_to_remove_ru, chr(11), E'\\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.how_to_remove_ru,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO wcc_magic_rituals (
  ms_id, dlc_dlc_id,
  level_id, form_id,
  effect_time_unit_id,
  preparing_time_unit_id,
  name_id, effect_id, how_to_remove_id,
  dc,
  preparing_time_value,
  ingredients,
  zone_size,
  stamina_cast, stamina_keeping,
  effect_time_value
)
SELECT rd.ms_id
     , rd.dlc_dlc_id
     , CASE WHEN nullif(rd.level_key,'') IS NOT NULL THEN ck_id(rd.level_key) ELSE NULL END AS level_id
     , CASE WHEN nullif(rd.form_key,'') IS NOT NULL THEN ck_id(rd.form_key) ELSE NULL END AS form_id
     , CASE
         WHEN rd.effect_time_unit_key LIKE 'time.unit.%' THEN ck_id(rd.effect_time_unit_key)
         ELSE NULL
       END AS effect_time_unit_id
     , ck_id('time.unit.round') AS preparing_time_unit_id
     , ck_id('witcher_cc.magic.ritual.name.'||rd.ms_id) AS name_id
     , ck_id('witcher_cc.magic.ritual.effect.'||rd.ms_id) AS effect_id
     , CASE WHEN nullif(rd.how_to_remove_ru,'') IS NOT NULL THEN ck_id('witcher_cc.magic.ritual.how_to_remove.'||rd.ms_id) ELSE NULL END AS how_to_remove_id
     , nullif(rd.dc,'')
     , NULLIF(rd.preparing_time_value,'')::int
     , rd.ingredients
     , nullif(rd.zone_size,'')
     , nullif(rd.stamina_cast,'')
     , nullif(rd.stamina_keeping,'')
     , nullif(rd.effect_time_value,'')
  FROM raw_data rd
ON CONFLICT (ms_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  level_id = EXCLUDED.level_id,
  form_id = EXCLUDED.form_id,
  effect_time_unit_id = EXCLUDED.effect_time_unit_id,
  preparing_time_unit_id = EXCLUDED.preparing_time_unit_id,
  name_id = EXCLUDED.name_id,
  effect_id = EXCLUDED.effect_id,
  how_to_remove_id = EXCLUDED.how_to_remove_id,
  dc = EXCLUDED.dc,
  preparing_time_value = EXCLUDED.preparing_time_value,
  ingredients = EXCLUDED.ingredients,
  zone_size = EXCLUDED.zone_size,
  stamina_cast = EXCLUDED.stamina_cast,
  stamina_keeping = EXCLUDED.stamina_keeping,
  effect_time_value = EXCLUDED.effect_time_value;
`;

  writeFile(outPath, sql);
}

function main() {
  const repoRoot = process.cwd();
  const tempDir = path.join(repoRoot, 'db/sql/items/temp');
  const outDir = path.join(repoRoot, 'db/sql/items');

  const maps = buildNameMaps(repoRoot);

  generateSpellsSql(
    repoRoot,
    path.join(outDir, '017_wcc_magic_spells.sql'),
    path.join(tempDir, 'wcc_items - wcc_magic_spells.tsv'),
  );
  generateHexesSql(
    repoRoot,
    path.join(outDir, '018_wcc_magic_hexes.sql'),
    path.join(tempDir, 'wcc_items - wcc_magic_hexes.tsv'),
    maps,
  );
  generateInvocationsSql(
    repoRoot,
    path.join(outDir, '019_wcc_magic_invocations.sql'),
    path.join(tempDir, 'wcc_items - wcc_magic_invocations.tsv'),
  );
  generateRitualsSql(
    repoRoot,
    path.join(outDir, '020_wcc_magic_rituals.sql'),
    path.join(tempDir, 'wcc_items - wcc_magic_rituals.tsv'),
    maps,
  );

  console.log('[generate_magic_sql] done');
}

main();


