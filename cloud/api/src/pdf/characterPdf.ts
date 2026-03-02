import * as fs from 'node:fs';
import * as path from 'node:path';
import PDFDocument from 'pdfkit';

type Lang = 'en' | 'ru';
type Row = { cells: string[] };
type Table = { title: string; columns: string[]; rows: Row[] };
type SkillCatalogLite = { param: string | null; name?: string };
type DefiningDisplay = {
  skillLine: string;
  basis: string;
  cells: {
    skillCur: string;
    skillBonus: string;
    skillRaceBonus: string;
    basis: string;
  };
};
type ValueCells = { cur: string; bonus: string; raceBonus: string; final: string };
type SkillSidebarRow = { name: string; cells: ValueCells };
type SkillSidebarGroup = { statId: string; title: string; statCells: ValueCells; rows: SkillSidebarRow[] };
type ProfBranchRow = { name: string; paramAbbr: string };
type ProfBranch = { title: string; color: 'blue' | 'mint' | 'rose'; rows: ProfBranchRow[] };
type LoreBlock = { label: string; value: string };
type SocialStatusGroup = { groupName: string; statusLabel: string; isFeared: boolean };
type StyleTableVm = { clothing: string; personality: string; hairStyle: string; affectations: string };
type ValuesTableVm = { valuedPerson: string; value: string; feelingsOnPeople: string };
type LifeEventRow = { period: string; type: string; description: string };
type SiblingRow = { age: string; gender: string; attitude: string; personality: string };
type AllyRow = { gender: string; position: string; where: string; howMet: string; howClose: string; isAlive: string };
type EnemyVmRow = { gender: string; position: string; victim: string; cause: string; power: string; level: string; result: string; alive: string };
type ItemEffectGlossaryRow = { name: string; value: string };
type RecipePageRow = {
  amount: string;
  recipeGroup: string;
  recipeName: string;
  complexity: string;
  timeCraft: string;
  formulaEn: string;
  priceFormula: string;
  minimalIngredientsCost: string;
  timeEffect: string;
  toxicity: string;
  recipeDescription: string;
  weightPotion: string;
  pricePotion: string;
};

type BlueprintPageRow = {
  amount: string;
  name: string;
  group: string;
  craftLevel: string;
  difficultyCheck: string;
  timeCraft: string;
  components: string;
  itemDesc: string;
  priceComponents: string;
  price: string;
  priceItem: string;
};

type ComponentPageRow = {
  amount: string;
  substanceEn: string;
  name: string;
  harvestingComplexity: string;
  weight: string;
  price: string;
};
type VehiclePageRow = {
  amount: string;
  subgroupName: string;
  vehicleName: string;
  base: string;
  controlModifier: string;
  speed: string;
  hp: string;
  weight: string;
  price: string;
  occupancy: string;
};
type GeneralGearPageRow = {
  amount: string;
  name: string;
  description: string;
  concealment: string;
  weight: string;
  price: string;
};
type MagicSpellLikeRow = {
  name: string;
  element: string;
  staminaCast: string;
  staminaKeeping: string;
  damage: string;
  distance: string;
  zoneSize: string;
  form: string;
  effectTime: string;
  tooltip: string;
};
type MagicInvocationRow = {
  name: string;
  group: string;
  staminaCast: string;
  staminaKeeping: string;
  damage: string;
  distance: string;
  zoneSize: string;
  form: string;
  effectTime: string;
  tooltip: string;
};
type MagicRitualRow = {
  name: string;
  level: string;
  dc: string;
  preparingTime: string;
  staminaCast: string;
  staminaKeeping: string;
  zoneSize: string;
  form: string;
  effectTime: string;
  ingredients: string;
  tooltip: string;
};
type MagicHexRow = {
  name: string;
  level: string;
  staminaCast: string;
  removeComponents: string;
  removeInstructions: string;
  tooltip: string;
};
type MagicGiftRow = {
  name: string;
  group: string;
  sl: string;
  vigor: string;
  cost: string;
  description: string;
};
type MagicGiftDetails = {
  mg_id: string;
  group_name: string | null;
  gift_name: string | null;
  dc: number | string | null;
  vigor_cost: number | string | null;
  action_cost?: number | string | null;
  description: string | null;
  sort_key: string | null;
  is_major: boolean | null;
};
type MagicPageVm = {
  onlyGiftsMagic: boolean;
  shouldRender: boolean;
  showSpellsSigns: boolean;
  showInvocations: boolean;
  showRituals: boolean;
  showHexes: boolean;
  showGifts: boolean;
  invocationsTitle: string;
  invocationsFill: string;
  spellsSignsRows: MagicSpellLikeRow[];
  invocationsRows: MagicInvocationRow[];
  ritualsRows: MagicRitualRow[];
  hexesRows: MagicHexRow[];
  giftsRows: MagicGiftRow[];
};
type MagicTableRowVm = {
  cells: string[];
  tooltip?: string;
};
type PdfTableSettingVm = {
  showIfEmpty: boolean;
  emptyRows: number;
};
type PdfTablesSettingsVm = {
  allies: PdfTableSettingVm;
  enemies: PdfTableSettingVm;
  alchemyRecipes: PdfTableSettingVm;
  blueprints: PdfTableSettingVm;
  components: PdfTableSettingVm;
  spellsSigns: PdfTableSettingVm;
  invocations: PdfTableSettingVm;
  rituals: PdfTableSettingVm;
  hexes: PdfTableSettingVm;
};

const COLORS = {
  page: '#ffffff',
  line: '#1f2d3a',
  text: '#111111',
  muted: '#616161',
  headerDefault: '#f3f4f6',
  headerPage2Blue: '#e7f1fe',   // rgba(59,130,246,0.12) over white
  headerSocial: '#feebde',      // rgba(249,115,22,0.14) over white
  headerAllies: '#e4f7eb',      // rgba(34,197,94,0.14) over white
  headerEnemies: '#fee4e4',     // rgba(239,68,68,0.14) over white
  headerSiblings: '#e5f6f4',    // rgba(20,184,166,0.14) over white
  headerRecipes: '#e4f7eb',     // rgba(34,197,94,0.14) over white
  headerBlueprints: '#efe8e3',  // rgba(139,90,43,0.12) over white
  headerMagicSpells: '#dbeafe', // rgba(147,197,253,0.35) over white
  headerMagicInvPriest: '#fed7aa', // rgba(253,186,116,0.35)
  headerMagicInvDruid: '#bbf7d0', // rgba(134,239,172,0.35)
  headerMagicRituals: '#ddd6fe', // rgba(196,181,253,0.35)
  headerMagicHexes: '#fecaca', // rgba(252,165,165,0.35)
  headerMagicGifts: '#a7f3d0', // rgba(110,231,183,0.28)
  headerPerks: '#fee3d0',       // rgba(249,115,22,0.20) over white
  headerWeapons: '#fdecec',     // rgba(239,68,68,0.10) over white
  headerArmors: '#ebf3fe',      // rgba(59,130,246,0.10) over white
  headerPotions: '#e7f8f2',     // rgba(16,185,129,0.10) over white
  headerMagicSummary: '#f6eefe', // rgba(168,85,247,0.10) over white
  headerNotes: '#f4e7dc',       // rgba(180,83,9,0.14) over white
  profBlue: '#eff5fe',          // rgba(59,130,246,0.08) over white
  profMint: '#ecf9f6',          // rgba(16,185,129,0.08) over white
  profRose: '#fef0f0',          // rgba(239,68,68,0.08) over white
  zebra: '#f5f5f5',
};

const FONTS = { regular: 'WccNotoSans', bold: 'WccNotoSansBold' } as const;
const PAGE = { margin: 20, gap: 8, headerH: 16 };
const RECIPE_PRIMARY_MIN_HEIGHT = 14;
const DEFAULT_PDF_TABLE_SETTINGS_VM: PdfTablesSettingsVm = {
  allies: { showIfEmpty: false, emptyRows: 0 },
  enemies: { showIfEmpty: false, emptyRows: 0 },
  alchemyRecipes: { showIfEmpty: true, emptyRows: 3 },
  blueprints: { showIfEmpty: true, emptyRows: 2 },
  components: { showIfEmpty: true, emptyRows: 3 },
  spellsSigns: { showIfEmpty: false, emptyRows: 0 },
  invocations: { showIfEmpty: false, emptyRows: 0 },
  rituals: { showIfEmpty: false, emptyRows: 0 },
  hexes: { showIfEmpty: false, emptyRows: 0 },
};

const SKILL_TO_STAT: Record<string, string> = {
  awareness: 'INT', business: 'INT', deduction: 'INT', education: 'INT', monster_lore: 'INT', tactics: 'INT', streetwise: 'INT',
  language_common_speech: 'INT', language_elder_speech: 'INT', language_dwarvish: 'INT', wilderness_survival: 'INT',
  brawling: 'REF', dodge: 'REF', melee: 'REF', riding: 'REF', sailing: 'REF', small_blades: 'REF', staff: 'REF', swordsmanship: 'REF',
  archery: 'DEX', athletics: 'DEX', crossbow: 'DEX', sleight_of_hand: 'DEX', stealth: 'DEX',
  endurance: 'BODY', physique: 'BODY',
  charisma: 'EMP', deceit: 'EMP', fine_arts: 'EMP', gambling: 'EMP', grooming_and_style: 'EMP', human_perception: 'EMP', leadership: 'EMP', persuasion: 'EMP', performance: 'EMP', seduction: 'EMP',
  alchemy: 'CRA', crafting: 'CRA', disguise: 'CRA', first_aid: 'CRA', forgery: 'CRA', pick_lock: 'CRA', trap_crafting: 'CRA',
  courage: 'WILL', hex_weaving: 'WILL', intimidation: 'WILL', spell_casting: 'WILL', resist_magic: 'WILL', resist_coercion: 'WILL', ritual_crafting: 'WILL',
};

const FORMULA_INGREDIENT_NAMES = [
  'Hydragenum',
  'Fulgur',
  'Vermilion',
  'Aether',
  'Vitriol',
  'Sol',
  'Rebis',
  'Quebrith',
  'Caelum',
  'Mutagen',
  'Spirits',
  'Dog Tallow',
] as const;

const MULTI_WORD_FORMULA_INGREDIENTS = new Set<string>(['Dog Tallow']);
const FORMULA_INGREDIENT_FILENAME_OVERRIDE: Record<string, string> = {
  'Dog Tallow': 'dog_tallow',
};

const formulaAssetPathCache = new Map<string, string | null>();

function tr(lang: Lang) {
  return {
    title: lang === 'ru' ? 'Лист персонажа' : 'Character Sheet',
    subtitle: lang === 'ru' ? 'Таверна "Сало и Огурчики" — облачный экспорт' : 'The Pickles and Lard Tavern — cloud export',
    top: {
      base: lang === 'ru' ? 'БАЗОВЫЕ ДАННЫЕ' : 'BASE DATA',
      main: lang === 'ru' ? 'ОСНОВНЫЕ ПАРАМЕТРЫ' : 'MAIN STATS',
      extra: lang === 'ru' ? 'ДОП. ПАРАМЕТРЫ' : 'EXTRA STATS',
      cons: lang === 'ru' ? 'РАСХОДУЕМЫЕ' : 'CONSUMABLES',
      avatar: lang === 'ru' ? 'АВАТАР' : 'AVATAR',
    },
    cols: {
      n: lang === 'ru' ? 'Название' : 'Name',
      v: lang === 'ru' ? 'Знач.' : 'Val',
      b: lang === 'ru' ? 'Бонус' : 'Bonus',
      max: lang === 'ru' ? 'МАКС' : 'MAX',
      cur: lang === 'ru' ? 'ТЕК' : 'CUR',
      qty: '#',
      dmg: lang === 'ru' ? 'Урон' : 'DMG',
      type: lang === 'ru' ? 'Тип' : 'Type',
      rel: lang === 'ru' ? 'Н' : 'Rel',
      hands: lang === 'ru' ? 'ХВАТ' : 'HANDS',
      conceal: lang === 'ru' ? 'СКР' : 'CONC',
      enh: lang === 'ru' ? 'УС' : 'ENH',
      wt: lang === 'ru' ? 'ВЕС' : 'WEIGHT',
      price: lang === 'ru' ? 'ЦЕНА' : 'PRICE',
      sp: lang === 'ru' ? 'ПБ' : 'SP',
      enc: lang === 'ru' ? 'СД' : 'Enc',
      tox: lang === 'ru' ? 'Токс' : 'Tox',
      time: lang === 'ru' ? 'Время' : 'Time',
      effect: lang === 'ru' ? 'Эффект' : 'Effect',
      field: lang === 'ru' ? 'Поле' : 'Field',
      note: lang === 'ru' ? 'Примечание' : 'Note',
    },
    labels: {
      name: lang === 'ru' ? 'Имя' : 'Name',
      race: lang === 'ru' ? 'Раса' : 'Race',
      gender: lang === 'ru' ? 'Пол' : 'Gender',
      age: lang === 'ru' ? 'Возраст' : 'Age',
      profession: lang === 'ru' ? 'Профессия' : 'Profession',
      def: lang === 'ru' ? 'Определяющий навык' : 'Defining skill',
      carry: lang === 'ru' ? 'Переносимый вес' : 'Carry',
      hp: lang === 'ru' ? 'Здоровье' : 'HP',
      sta: lang === 'ru' ? 'Выносливость' : 'STA',
      resolve: lang === 'ru' ? 'Решимость' : 'Resolve',
      luck: lang === 'ru' ? 'Удача' : 'Luck',
      enc: lang === 'ru' ? 'Переносимый вес' : 'Carry',
      rec: lang === 'ru' ? 'Отдых' : 'Recovery',
      stun: lang === 'ru' ? 'Уст.' : 'Stun',
      run: lang === 'ru' ? 'Бег' : 'Run',
      leap: lang === 'ru' ? 'Прыж.' : 'Leap',
      punch: lang === 'ru' ? 'Уд.р.' : 'Punch',
      kick: lang === 'ru' ? 'Уд.н.' : 'Kick',
      vigor: lang === 'ru' ? 'Энергия' : 'Vigor',
    },
    statsAbbr: lang === 'ru'
      ? { INT: 'ИНТ', REF: 'РЕФ', DEX: 'ЛОВ', BODY: 'ТЕЛ', SPD: 'СКР', EMP: 'ЭМП', CRA: 'РЕМ', WILL: 'ВОЛ', LUCK: 'УДА', VIGOR: 'ЭНЕРГИЯ' }
      : { INT: 'INT', REF: 'REF', DEX: 'DEX', BODY: 'BODY', SPD: 'SPD', EMP: 'EMP', CRA: 'CRA', WILL: 'WILL', LUCK: 'LUCK', VIGOR: 'VIGOR' },
    statsFull: lang === 'ru'
      ? { INT: 'ИНТЕЛЛЕКТ', REF: 'РЕФЛЕКСЫ', DEX: 'ЛОВКОСТЬ', BODY: 'ТЕЛО', SPD: 'СКОРОСТЬ', EMP: 'ЭМПАТИЯ', CRA: 'РЕМЕСЛО', WILL: 'ВОЛЯ', OTHER: 'ПРОЧЕЕ' }
      : { INT: 'INTELLIGENCE', REF: 'REFLEXES', DEX: 'DEXTERITY', BODY: 'BODY', SPD: 'SPEED', EMP: 'EMPATHY', CRA: 'CRAFT', WILL: 'WILL', OTHER: 'OTHER' },
    baseWord: lang === 'ru' ? 'Основа' : 'Base',
    sections: {
      skills: lang === 'ru' ? 'НАВЫКИ' : 'SKILLS',
      prof: lang === 'ru' ? 'ПРОФЕССИОНАЛЬНЫЕ НАВЫКИ' : 'PROFESSIONAL SKILLS',
      perks: lang === 'ru' ? 'ПЕРКИ' : 'PERKS',
      weapons: lang === 'ru' ? 'ОРУЖИЕ' : 'WEAPONS',
      armor: lang === 'ru' ? 'БРОНЯ' : 'ARMOR',
      alchemy: lang === 'ru' ? 'АЛХИМИЯ' : 'ALCHEMY',
      magic: lang === 'ru' ? 'МАГИЯ' : 'MAGIC',
      lore: lang === 'ru' ? 'ЛОР И БИОГРАФИЯ' : 'LORE & BIOGRAPHY',
      notes: lang === 'ru' ? 'ЗАМЕТКИ' : 'NOTES',
      recipes: lang === 'ru' ? 'РЕЦЕПТЫ' : 'RECIPES',
    },
    page1: {
      magicCols: {
        type: lang === 'ru' ? 'ТИП' : 'TYPE',
        name: lang === 'ru' ? 'НАЗВАНИЕ' : 'NAME',
        element: lang === 'ru' ? 'ЭЛЕМЕНТ' : 'ELEMENT',
        vigor: lang === 'ru' ? 'ВЫН' : 'VIG',
        vigorKeep: lang === 'ru' ? 'ВЫН+' : 'VIG+',
        damage: lang === 'ru' ? 'УРОН' : 'DMG',
        time: lang === 'ru' ? 'ВРЕМЯ' : 'TIME',
        distance: lang === 'ru' ? 'ДИСТ' : 'DIST',
        size: lang === 'ru' ? 'РАЗМЕР' : 'SIZE',
        form: lang === 'ru' ? 'ФОРМА' : 'FORM',
      },
      magicTypes: {
        sign: lang === 'ru' ? 'Знак' : 'Sign',
        spell: lang === 'ru' ? 'Закл.' : 'Spell',
        invocation: lang === 'ru' ? 'Инв.' : 'Inv.',
      },
    },
    page2: {
      socialStatusRace: lang === 'ru' ? 'СОЦИАЛЬНЫЙ СТАТУС' : 'SOCIAL STATUS',
      lore: lang === 'ru' ? 'ЛОР' : 'LORE',
      style: lang === 'ru' ? 'СТИЛЬ' : 'STYLE',
      values: lang === 'ru' ? 'ЦЕННОСТИ' : 'VALUES',
      lifePath: lang === 'ru' ? 'ЖИЗНЕННЫЙ ПУТЬ' : 'LIFE PATH',
      siblings: lang === 'ru' ? 'БРАТЬЯ И СЁСТРЫ' : 'SIBLINGS',
      allies: lang === 'ru' ? 'СОЮЗНИКИ' : 'ALLIES',
      enemies: lang === 'ru' ? 'ВРАГИ' : 'ENEMIES',
      itemEffects: lang === 'ru' ? 'ЭФФЕКТЫ ПРЕДМЕТОВ' : 'ITEM EFFECTS',
      socialStatus: {
        equal: lang === 'ru' ? 'Равенство' : 'Equal',
        tolerated: lang === 'ru' ? 'Терпимость' : 'Tolerated',
        hated: lang === 'ru' ? 'Ненависть' : 'Hated',
        fearedSuffix: lang === 'ru' ? 'и Опасение' : 'and Feared',
      },
      loreLabels: {
        homeland: lang === 'ru' ? 'Родина' : 'Homeland',
        homeLanguage: lang === 'ru' ? 'Родной язык' : 'Home language',
        familyStatus: lang === 'ru' ? 'Статус семьи' : 'Family status',
        familyFate: lang === 'ru' ? 'Судьба семьи' : 'Family fate',
        parentsFate: lang === 'ru' ? 'Судьба родителей' : 'Parents fate',
        friend: lang === 'ru' ? 'Друг' : 'Friend',
        school: lang === 'ru' ? 'Школа' : 'School',
        initiation: lang === 'ru' ? 'Посвящение' : 'Initiation',
        diseases: lang === 'ru' ? 'Болезни и проклятия' : 'Diseases and curses',
        importantEvent: lang === 'ru' ? 'Самое важное событие' : 'Most important event',
        trainings: lang === 'ru' ? 'Тренировки' : 'Trainings',
        currentSituation: lang === 'ru' ? 'Текущая ситуация' : 'Current situation',
      },
      styleCols: {
        clothing: lang === 'ru' ? 'Одежда' : 'Clothing',
        personality: lang === 'ru' ? 'Характер' : 'Personality',
        hairStyle: lang === 'ru' ? 'Причёска' : 'Hairstyle',
        affectations: lang === 'ru' ? 'Украшения' : 'Affectations',
      },
      valuesCols: {
        valuedPerson: lang === 'ru' ? 'Кого ценит' : 'Valued person',
        value: lang === 'ru' ? 'Что ценит' : 'Value',
        feelingsOnPeople: lang === 'ru' ? 'Мысли об окружающих' : 'Feelings on people',
      },
      lifeEventCols: {
        period: lang === 'ru' ? 'Период' : 'Period',
        type: lang === 'ru' ? 'Тип' : 'Type',
        description: lang === 'ru' ? 'Описание' : 'Description',
      },
      siblingsCols: {
        age: lang === 'ru' ? 'Возраст' : 'Age',
        gender: lang === 'ru' ? 'Пол' : 'Sex',
        attitude: lang === 'ru' ? 'Отношение' : 'Attitude',
        personality: lang === 'ru' ? 'Характер' : 'Personality',
      },
      alliesCols: {
        gender: lang === 'ru' ? 'Пол' : 'Sex',
        position: lang === 'ru' ? 'Кто' : 'Who',
        where: lang === 'ru' ? 'Где он сейчас' : 'Where now',
        acquaintance: lang === 'ru' ? 'Знакомство' : 'Acquaintance',
        howMet: lang === 'ru' ? 'Как встретились' : 'How met',
        howClose: lang === 'ru' ? 'Близость' : 'Closeness',
        alive: lang === 'ru' ? 'Жив ли' : 'Alive',
      },
      enemiesCols: {
        gender: lang === 'ru' ? 'Пол' : 'Sex',
        position: lang === 'ru' ? 'Кто' : 'Who',
        victim: lang === 'ru' ? 'Жертва' : 'Victim',
        cause: lang === 'ru' ? 'Причина' : 'Cause',
        power: lang === 'ru' ? 'Сила' : 'Power',
        level: lang === 'ru' ? 'Мощь' : 'Level',
        result: lang === 'ru' ? 'Итог' : 'Result',
        alive: lang === 'ru' ? 'Жив ли' : 'Alive',
        howFar: lang === 'ru' ? 'Насколько далеко' : 'How far',
      },
    },
    page3: {
      recipes: lang === 'ru' ? 'РЕЦЕПТЫ' : 'RECIPES',
      blueprints: lang === 'ru' ? 'ЧЕРТЕЖИ' : 'BLUEPRINTS',
      money: lang === 'ru' ? 'ДЕНЬГИ' : 'MONEY',
      transport: lang === 'ru' ? 'ТРАНСПОРТ' : 'TRANSPORT',
      generalGear: lang === 'ru' ? 'ОБЩЕЕ СНАРЯЖЕНИЕ' : 'GENERAL GEAR',
      recipesCols: {
        qty: '#',
        recipeGroup: lang === 'ru' ? 'ГРУППА' : 'GROUP',
        recipeName: lang === 'ru' ? 'РЕЦЕПТ' : 'RECIPE',
        complexity: lang === 'ru' ? 'СЛ' : 'DC',
        timeCraft: lang === 'ru' ? 'ВРЕМЯ\nКРАФТА' : 'CRAFT\nTIME',
        formula: lang === 'ru' ? 'ФОРМУЛА' : 'FORMULA',
        priceFormula: lang === 'ru' ? 'ЦЕНА\nФ-ЛЫ' : 'F-LA\nPRICE',
        minimalIngredientsCost: lang === 'ru' ? 'МИН.\nЦЕНА\nИНГР.' : 'MIN.\nINGR.\nCOST',
        timeEffect: lang === 'ru' ? 'ВРЕМЯ\nЭФФЕКТА' : 'EFFECT\nTIME',
        toxicity: lang === 'ru' ? 'ТОКС.' : 'TOX.',
        recipeDescription: lang === 'ru' ? 'ЭФФЕКТ' : 'EFFECT',
        weightPotion: lang === 'ru' ? 'ВЕС' : 'WEIGHT',
        pricePotion: lang === 'ru' ? 'ЦЕНА' : 'PRICE',
      },
      blueprintsCols: {
        qty: '#',
        name: lang === 'ru' ? 'ИМЯ' : 'NAME',
        craftLevel: lang === 'ru' ? 'УРОВ.' : 'LEVEL',
        difficultyCheck: lang === 'ru' ? 'СЛ' : 'DC',
        timeCraft: lang === 'ru' ? 'ВРЕМЯ\nКРАФТА' : 'CRAFT\nTIME',
        components: lang === 'ru' ? 'СОСТАВ' : 'COMPONENTS',
        itemDesc: lang === 'ru' ? 'ОПИСАНИЕ' : 'DESC',
        priceComponents: lang === 'ru' ? 'ДОПЛАТА' : 'SURCHARGE',
        price: lang === 'ru' ? 'ЦЕНА\nСХЕМЫ' : 'BLUEPRINT\nCOST',
        priceItem: lang === 'ru' ? 'ЦЕНА\nВЕЩИ' : 'ITEM\nCOST',
      },
      componentsCols: {
        qty: '#',
        sub: lang === 'ru' ? 'C' : 'S',
        name: lang === 'ru' ? 'КОМПОНЕНТ' : 'COMPONENT',
        harvestingComplexity: lang === 'ru' ? 'СЛ' : 'DC',
        weight: lang === 'ru' ? 'ВЕС' : 'WEIGHT',
        price: lang === 'ru' ? 'Ц' : 'PR',
      },
      moneyCols: {
        crowns: lang === 'ru' ? 'КРОНЫ' : 'CROWNS',
        orens: lang === 'ru' ? 'ОРЕНЫ' : 'ORENS',
        florens: lang === 'ru' ? 'ФЛОРЕНЫ' : 'FLORENS',
        ducats: lang === 'ru' ? 'ДУКАТЫ' : 'DUCATS',
        bizants: lang === 'ru' ? 'БИЗАНТЫ' : 'BIZANTS',
        lintars: lang === 'ru' ? 'ЛИНТАРЫ' : 'LINTARS',
      },
      transportCols: {
        qty: '#',
        type: lang === 'ru' ? 'ТИП' : 'TYPE',
        name: lang === 'ru' ? 'ТРАНСПОРТ' : 'VEHICLE',
        skill: lang === 'ru' ? 'НАВЫК' : 'SKILL',
        mod: lang === 'ru' ? 'МОД.' : 'MOD.',
        speed: lang === 'ru' ? 'СКОР.' : 'SPEED',
        hp: lang === 'ru' ? 'ПЗ' : 'HP',
        weight: lang === 'ru' ? 'ВЕС' : 'WEIGHT',
        price: lang === 'ru' ? 'ЦЕНА' : 'PRICE',
        occupancy: lang === 'ru' ? 'МЕСТА' : 'SEATS',
      },
      generalGearCols: {
        qty: '#',
        name: lang === 'ru' ? 'ИМЯ' : 'NAME',
        concealment: lang === 'ru' ? 'СКР' : 'CONC',
        weight: lang === 'ru' ? 'ВЕС' : 'WEIGHT',
        price: lang === 'ru' ? 'ЦЕНА' : 'PRICE',
      },
      formulaLegend: {
        Hydragenum: lang === 'ru' ? 'Гидраген' : 'Hydragenum',
        Fulgur: lang === 'ru' ? 'Фульгор' : 'Fulgur',
        Vermilion: lang === 'ru' ? 'Киноварь' : 'Vermilion',
        Aether: lang === 'ru' ? 'Эфир' : 'Aether',
        Vitriol: lang === 'ru' ? 'Купорос' : 'Vitriol',
        Sol: lang === 'ru' ? 'Солнце' : 'Sol',
        Rebis: lang === 'ru' ? 'Ребис' : 'Rebis',
        Quebrith: lang === 'ru' ? 'Квебрит' : 'Quebrith',
        Caelum: lang === 'ru' ? 'Аер' : 'Caelum',
        Mutagen: lang === 'ru' ? 'Мутаген' : 'Mutagen',
        Spirits: lang === 'ru' ? 'Алкоголь' : 'Spirits',
        DogTallow: lang === 'ru' ? 'Собачье сало' : 'Dog Tallow',
      },
    },
    page4: {
      titles: {
        spellsSigns: lang === 'ru' ? 'ЗАКЛИНАНИЯ / ЗНАКИ' : 'SPELLS / SIGNS',
        invocationsPriest: lang === 'ru' ? 'ИНВОКАЦИИ ЖРЕЦА' : 'PRIEST INVOCATIONS',
        invocationsDruid: lang === 'ru' ? 'ИНВОКАЦИИ ДРУИДА' : 'DRUID INVOCATIONS',
        rituals: lang === 'ru' ? 'РИТУАЛЫ' : 'RITUALS',
        hexes: lang === 'ru' ? 'ПОРЧИ' : 'HEXES',
        gifts: lang === 'ru' ? 'МАГИЧЕСКИЕ ДАРЫ' : 'MAGICAL GIFTS',
      },
      cols: {
        name: lang === 'ru' ? 'ИМЯ' : 'NAME',
        element: lang === 'ru' ? 'ЭЛЕМЕНТ' : 'ELEMENT',
        level: lang === 'ru' ? 'УРОВЕНЬ' : 'LEVEL',
        group: lang === 'ru' ? 'ГРУППА' : 'GROUP',
        staminaCast: lang === 'ru' ? 'ВЫН' : 'STA',
        staminaKeeping: lang === 'ru' ? 'ВЫН+' : 'STA+',
        damage: lang === 'ru' ? 'УРОН' : 'DAMAGE',
        distance: lang === 'ru' ? 'ДИСТ.' : 'RNG.',
        zoneSize: lang === 'ru' ? 'ЗОНА' : 'AREA',
        form: lang === 'ru' ? 'ФОРМА' : 'FORM',
        preparingTime: lang === 'ru' ? 'ПОДГ.' : 'PREP',
        dc: lang === 'ru' ? 'СЛ' : 'DC',
        effectTime: lang === 'ru' ? 'ВРЕМЯ' : 'TIME',
        ingredients: lang === 'ru' ? 'КОМПОНЕНТЫ' : 'COMPONENTS',
        removeComponents: lang === 'ru' ? 'КОМПОНЕНТЫ ДЛЯ СНЯТИЯ' : 'REMOVE COMPONENTS',
        removeInstructions: lang === 'ru' ? 'КАК СНЯТЬ' : 'HOW TO REMOVE',
      },
      gifts: {
        colName: lang === 'ru' ? 'ИМЯ' : 'NAME',
        colGroup: lang === 'ru' ? 'ГРУППА' : 'GROUP',
        colSl: lang === 'ru' ? 'СЛ' : 'DC',
        colVigor: lang === 'ru' ? 'ВЫН' : 'STA',
        colCost: lang === 'ru' ? 'СТОИМОСТЬ' : 'COST',
        costAction: lang === 'ru' ? 'действие' : 'action',
        costFullAction: lang === 'ru' ? 'полное действие' : 'full action',
      },
    },
    avatarPlaceholder: lang === 'ru' ? 'Портрет не загружен' : 'Portrait not provided',
  };
}

function asRecord(v: unknown): Record<string, unknown> | null {
  return v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : null;
}
function asArray(v: unknown): unknown[] { return Array.isArray(v) ? v : []; }
function num(v: unknown): number | null {
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string' && v.trim()) { const n = Number(v); return Number.isFinite(n) ? n : null; }
  return null;
}
function clonePdfTableSettingsDefaults(): PdfTablesSettingsVm {
  return {
    allies: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.allies },
    enemies: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.enemies },
    alchemyRecipes: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.alchemyRecipes },
    blueprints: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.blueprints },
    components: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.components },
    spellsSigns: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.spellsSigns },
    invocations: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.invocations },
    rituals: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.rituals },
    hexes: { ...DEFAULT_PDF_TABLE_SETTINGS_VM.hexes },
  };
}
function clampPdfEmptyRows(v: unknown): number {
  const n = num(v);
  if (n == null) return 0;
  return Math.max(0, Math.min(50, Math.trunc(n)));
}
function normalizePdfTableSettings(
  root: Record<string, unknown> | null,
): PdfTablesSettingsVm {
  const out = clonePdfTableSettingsDefaults();
  const source =
    asRecord(root?.pdf_tables) ??
    asRecord(root?.pdfTables) ??
    null;
  if (!source) return out;
  const keys = Object.keys(out) as Array<keyof PdfTablesSettingsVm>;
  for (const key of keys) {
    const node = asRecord(source[key]);
    if (!node) continue;
    const show =
      (typeof node.showIfEmpty === 'boolean' ? node.showIfEmpty : null) ??
      (typeof node.show_if_empty === 'boolean' ? node.show_if_empty : null);
    const rowsRaw = node.emptyRows ?? node.empty_rows;
    if (show != null) out[key].showIfEmpty = show;
    if (rowsRaw != null) out[key].emptyRows = clampPdfEmptyRows(rowsRaw);
  }
  return out;
}
function text(v: unknown, none = '—'): string {
  if (v == null) return none;
  if (typeof v === 'string') return v.trim() || none;
  if (typeof v === 'number') return Number.isFinite(v) ? String(v) : none;
  if (Array.isArray(v)) return v.map((x) => text(x, '')).filter(Boolean).join(', ') || none;
  const r = asRecord(v);
  if (!r) return none;
  for (const k of ['name', 'label', 'title', 'text', 'value']) {
    if (typeof r[k] === 'string' && (r[k] as string).trim()) return (r[k] as string).trim();
  }
  if (typeof r.i18n_uuid === 'string') return r.i18n_uuid as string;
  return JSON.stringify(r);
}
function pretty(k: string): string {
  return k.replace(/^language_/, 'language ').replace(/_/g, ' ').replace(/\b\w/g, (m) => m.toUpperCase());
}
function stripHtmlTags(s: string): string {
  return s.replace(/<[^>]*>/g, '').trim();
}
function normalizeMinusChars(s: string): string {
  // Normalize minus-like characters to ASCII hyphen-minus, but keep em/en dashes intact.
  return s
    .replace(/\u2212/g, '-') // minus sign
    .replace(/\u2011/g, '-') // non-breaking hyphen
    .replace(/\u2010/g, '-'); // hyphen
}
function normalizeInlineEffects(s: string): string {
  return normalizeMinusChars(stripHtmlTags(s))
    .replace(/\r?\n+/g, ', ')
    .replace(/\s*\|\s*/g, ', ')
    .replace(/\s*;\s*/g, ', ')
    .replace(/\s*,\s*/g, ', ')
    .replace(/,\s*,+/g, ', ')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

function containsAnyNeedle(haystackLower: string, needles: readonly string[]): boolean {
  return needles.some((needle) => haystackLower.includes(needle));
}

function normalizeComponentsMultiline(rawValue: string): string {
  const value = String(rawValue ?? '').trim();
  if (!value) return '';
  return value
    .replace(/,\s*\r?\n\s*-\s*/g, '\n- ')
    .replace(/^\s*-\s*/gm, '- ')
    .replace(/^\s*\r?\n/, '')
    .trim();
}

function stripRitualComponentsFromEffect(rawValue: string): string {
  const value = String(rawValue ?? '').trim();
  if (!value) return '';
  const match = /\n\s*\n(?:Компоненты:|Components:)\s*\n/i;
  const idx = value.search(match);
  if (idx < 0) return value;
  return value.slice(0, idx).trim();
}

function formatDiseaseOrCurseEntry(entry: unknown): string {
  if (entry == null) return '';
  if (typeof entry === 'string') return entry.trim();
  const rec = asRecord(entry);
  if (!rec) return text(entry, '').trim();
  const type = text(rec.type, '').trim();
  const name = text(rec.name, '').trim();
  const description = text(rec.description, '').trim();
  if (name && description) return `<b>${name}:</b> ${description}`;
  if (name) return name;
  if (type && description) return `<b>${type}:</b> ${description}`;
  return description || text(entry, '').trim();
}

type RichToken = { text: string; bold: boolean; italic: boolean } | { newline: true };

function parseRichInlineTokens(input: string): RichToken[] {
  const src = input
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/&nbsp;/gi, ' ');
  const tokens: RichToken[] = [];
  const tagRe = /<\/?(b|strong|i|em)\s*>/gi;
  let bold = false;
  let italic = false;
  let last = 0;
  let match: RegExpExecArray | null;
  while ((match = tagRe.exec(src)) !== null) {
    const chunk = src.slice(last, match.index);
    if (chunk) {
      const parts = chunk.split('\n');
      for (let i = 0; i < parts.length; i += 1) {
        if (parts[i]) tokens.push({ text: parts[i]!, bold, italic });
        if (i < parts.length - 1) tokens.push({ newline: true });
      }
    }
    const tag = match[0].toLowerCase();
    const isClose = tag.startsWith('</');
    const name = match[1].toLowerCase();
    if (name === 'b' || name === 'strong') bold = !isClose;
    if (name === 'i' || name === 'em') italic = !isClose;
    last = match.index + match[0].length;
  }
  const tail = src.slice(last);
  if (tail) {
    const parts = tail.split('\n');
    for (let i = 0; i < parts.length; i += 1) {
      if (parts[i]) tokens.push({ text: parts[i]!, bold, italic });
      if (i < parts.length - 1) tokens.push({ newline: true });
    }
  }
  return tokens;
}
function calcDerivedDiceFromBody(bodyCur: number, kind: 'punch' | 'kick'): string {
  const mod = kind === 'punch'
    ? 2 * Math.trunc((bodyCur - 1) / 2) - 4
    : 2 * Math.trunc((bodyCur - 1) / 2);
  if (mod === 0) return '1d6';
  return mod > 0 ? `1d6+${mod}` : `1d6${mod}`;
}
function statValue(r: Record<string, unknown> | null): { cur: string; bonus: string; full: string } {
  const rec = r ?? {};
  const cur = num(rec.cur ?? rec.value ?? rec.total);
  const b1 = num(rec.bonus ?? rec.mod);
  const b2 = num(rec.race_bonus);
  const bonusParts = [b1, b2].filter((x): x is number => x != null && x !== 0).map((x) => (x > 0 ? `+${x}` : String(x)));
  const fullParts = [cur != null ? String(cur) : '', ...bonusParts].filter(Boolean);
  return { cur: cur == null ? '—' : String(cur), bonus: bonusParts.join(' ') || '—', full: fullParts.join(' ') || '—' };
}

function fontPaths(): { regular: string; bold: string } {
  const regular = [
    '/var/task/pdf-fonts/NotoSans-Regular.ttf',
    path.join(process.cwd(), 'src', 'pdf', 'fonts', 'NotoSans-Regular.ttf'),
    path.join(process.cwd(), 'cloud', 'api', 'src', 'pdf', 'fonts', 'NotoSans-Regular.ttf'),
  ].find((p) => fs.existsSync(p));
  const bold = [
    '/var/task/pdf-fonts/NotoSans-Bold.ttf',
    path.join(process.cwd(), 'src', 'pdf', 'fonts', 'NotoSans-Bold.ttf'),
    path.join(process.cwd(), 'cloud', 'api', 'src', 'pdf', 'fonts', 'NotoSans-Bold.ttf'),
  ].find((p) => fs.existsSync(p));
  if (!regular || !bold) throw new Error('NotoSans fonts not found for PDF rendering');
  return { regular, bold };
}

function formulaIngredientAssetPath(englishName: string, alchemyStyle: 'w1' | 'w2' = 'w2'): string | null {
  const cacheKey = `${alchemyStyle}:${englishName}`;
  if (formulaAssetPathCache.has(cacheKey)) return formulaAssetPathCache.get(cacheKey) ?? null;
  const filenameBase = FORMULA_INGREDIENT_FILENAME_OVERRIDE[englishName] ?? englishName;
  const extensions = ['png', 'webp'];
  const candidates: string[] = [];
  for (const ext of extensions) {
    const filename = `${filenameBase}.${ext}`;
    candidates.push(
      path.join('/var/task', 'assets', 'formula_ingredients', alchemyStyle, filename),
      path.join(process.cwd(), 'src', 'pdf', 'assets', 'formula_ingredients', alchemyStyle, filename),
      path.join(process.cwd(), 'cloud', 'api', 'src', 'pdf', 'assets', 'formula_ingredients', alchemyStyle, filename),
      path.join(process.cwd(), 'apps', 'api', 'src', 'pdf', 'assets', 'formula_ingredients', alchemyStyle, filename),
    );
  }
  const resolved = candidates.find((p) => fs.existsSync(p)) ?? null;
  formulaAssetPathCache.set(cacheKey, resolved);
  return resolved;
}

function tokenizeFormulaIngredients(formulaEn: string): string[] {
  const rawTokens = String(formulaEn ?? '').trim().split(/\s+/).filter(Boolean);
  const tokens: string[] = [];
  for (let i = 0; i < rawTokens.length; ) {
    const two = i + 1 < rawTokens.length ? `${rawTokens[i]} ${rawTokens[i + 1]}`.trim() : '';
    if (two && MULTI_WORD_FORMULA_INGREDIENTS.has(two)) {
      tokens.push(two);
      i += 2;
    } else {
      tokens.push(rawTokens[i]!);
      i += 1;
    }
  }
  return tokens;
}

function buildVm(resolved: Record<string, unknown>, raw: Record<string, unknown>, lang: Lang) {
  return buildVmWithCatalog(resolved, raw, lang, undefined, undefined);
}

function buildVmWithCatalog(
  resolved: Record<string, unknown>,
  raw: Record<string, unknown>,
  lang: Lang,
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>,
  itemEffectsGlossary?: ReadonlyArray<ItemEffectGlossaryRow>,
) {
  const tx = tr(lang);
  const userSettings =
    asRecord(raw.user_settings) ??
    asRecord(raw.userSettings) ??
    null;
  const pdfTableSettings = normalizePdfTableSettings(userSettings);
  const useW1AlchemyIcons =
    (typeof userSettings?.use_w1_alchemy_icons === 'boolean' && userSettings.use_w1_alchemy_icons) ||
    (typeof userSettings?.useW1AlchemyIcons === 'boolean' && userSettings.useW1AlchemyIcons) ||
    false;
  const alchemyIconStyle: 'w1' | 'w2' = useW1AlchemyIcons ? 'w1' : 'w2';
  const stats = asRecord(resolved.statistics) ?? {};
  const rawStats = asRecord(raw.statistics) ?? {};
  const calc = asRecord(stats.calculated) ?? {};
  const logic = asRecord(raw.logicFields) ?? asRecord(raw.logic_fields) ?? {};
  const defining = asRecord(asRecord(resolved.skills)?.defining);
  const skillsCommon = asRecord(asRecord(resolved.skills)?.common) ?? {};
  const rawSkillsCommon = asRecord(asRecord(raw.skills)?.common) ?? skillsCommon;
  const definingCalc = calcDefiningDisplay({
    statistics: rawStats,
    skillsCommon: rawSkillsCommon,
    defining,
    statAbbr: tx.statsAbbr,
    skillsCatalogById,
  });

  const baseRows = [
    { label: tx.labels.name, value: text(resolved.name) },
    { label: tx.labels.race, value: text(resolved.race) },
    { label: tx.labels.gender, value: text(resolved.gender) },
    { label: tx.labels.age, value: text(resolved.age) },
    { label: tx.labels.profession, value: text(resolved.profession ?? logic.profession ?? logic.profession_code) },
  ];

  const mainStats = ['INT','REF','DEX','BODY','SPD','EMP','CRA','WILL','LUCK','vigor'].map((k) => {
    const statCells = valueCellsFromStatish(asRecord(rawStats[k] ?? stats[k]));
    const abbr =
      k === 'vigor'
        ? tx.statsAbbr.VIGOR
        : k === 'LUCK'
          ? tx.statsAbbr.LUCK
          : tx.statsAbbr[k as keyof typeof tx.statsAbbr] ?? k.toUpperCase();
    return { cells: [abbr, statCells.cur || '0', statCells.bonus, statCells.raceBonus] };
  });
  const bodyCurForDerived = num(asRecord(stats.BODY)?.cur) ?? 0;
  const extraStats = [
    [tx.labels.run, calc.run], [tx.labels.leap, calc.leap],
    [tx.labels.stun, calc.STUN], [tx.labels.rec, calc.REC],
    [tx.labels.punch, calc.bonus_punch], [tx.labels.kick, calc.bonus_kick],
    [tx.labels.vigor, stats.vigor],
  ].map(([k, v]) => {
    const rec = asRecord(v);
    const curStr = typeof rec?.cur === 'string' ? rec.cur.trim() : '';
    let display = statValue(rec).full;
    if (curStr) {
      display = curStr;
    } else if (k === tx.labels.punch || k === tx.labels.kick) {
      display = calcDerivedDiceFromBody(bodyCurForDerived, k === tx.labels.punch ? 'punch' : 'kick');
    }
    return { cells: [String(k), display] };
  });
  const consRows = [
    [tx.labels.carry, calc.ENC, ''],
    [tx.labels.hp, calc.max_HP, ''],
    [tx.labels.sta, calc.STA, ''],
    [tx.labels.resolve, { cur: calcResolve(stats) }, ''],
    [tx.labels.luck, stats.LUCK, ''],
  ].map(([k, v, cur]) => ({ cells: [String(k), statValue(asRecord(v)).full, String(cur || '')] }));

  const grouped = new Map<string, Row[]>();
  const skillSidebarGrouped = new Map<string, SkillSidebarRow[]>();
  const canonicalSkillId = (skillId: string): string => {
    if (skillId === 'dodge') return 'dodge_escape';
    if (skillId === 'staff') return 'staff_spear';
    return skillId;
  };
  const definingSkillId = typeof defining?.id === 'string' ? defining.id : '';
  const definingSkillCanonicalId = definingSkillId ? canonicalSkillId(definingSkillId) : '';
  const paramFallbackBySkillId = (skillId: string): string | null => {
    if (skillId === 'staff') return 'REF';
    if (skillId === 'dodge') return 'REF';
    if (skillId === 'sailing') return 'REF';
    if (skillId === 'small_blades') return 'REF';
    if (skillId === 'swordsmanship') return 'REF';
    if (skillId === 'melee') return 'REF';
    if (skillId === 'brawling') return 'REF';
    return null;
  };
  const languageSkillFallbackName = (id: string): string => {
    if (!id.startsWith('language_')) return '';
    const suffix = id.slice('language_'.length);
    if (lang === 'ru') {
      const map: Record<string, string> = {
        common_speech: 'Язык: Всеобщий',
        elder_speech: 'Язык: Старшая речь',
        dwarvish: 'Язык: Краснолюдский',
      };
      return map[suffix] ?? `Язык: ${suffix.replace(/_/g, ' ')}`;
    }
    const map: Record<string, string> = {
      common_speech: 'Language Common Speech',
      elder_speech: 'Language Elder Speech',
      dwarvish: 'Language Dwarvish',
    };
    return map[suffix] ?? pretty(id);
  };
  for (const [skillId, rawValue] of Object.entries(rawSkillsCommon)) {
    const v = statValue(asRecord(rawValue)).full;
    const metaId = canonicalSkillId(skillId);
    if (skillId === definingSkillId || (definingSkillCanonicalId && metaId === definingSkillCanonicalId)) continue;
    const catalog = skillsCatalogById?.get(metaId) ?? skillsCatalogById?.get(skillId);
    const key = ((catalog?.param?.toUpperCase()) || paramFallbackBySkillId(metaId) || SKILL_TO_STAT[metaId] || SKILL_TO_STAT[skillId] || 'OTHER').toUpperCase();
    const arr = grouped.get(key) ?? [];
    const fallbackLangName = languageSkillFallbackName(skillId);
    const displayName = (catalog?.name?.trim() || text(asRecord(rawValue)?.name, '') || fallbackLangName || pretty(skillId));
    arr.push({ cells: [displayName, v] });
    grouped.set(key, arr);
    const sidebarArr = skillSidebarGrouped.get(key) ?? [];
    sidebarArr.push({
      name: displayName,
      cells: (() => {
        const skillRec = asRecord(rawValue) ?? {};
        const skillCur = num(skillRec.cur) ?? 0;
        const skillBonus = num(skillRec.bonus ?? skillRec.mod) ?? 0;
        const skillRaceBonus = num(skillRec.race_bonus) ?? 0;
        const statRec = asRecord(rawStats[key]) ?? {};
        const statCur = num(statRec.cur) ?? 0;
        const statBonus = num(statRec.bonus ?? statRec.mod) ?? 0;
        const statRaceBonus = num(statRec.race_bonus) ?? 0;
        const base =
          calcStatFinal(statCur, statBonus, statRaceBonus) +
          calcSkillContribution(skillCur, skillBonus, skillRaceBonus);
        const hasOwnContribution = skillCur !== 0 || skillBonus !== 0 || skillRaceBonus !== 0;
        return {
          cur: skillCur === 0 ? '' : String(skillCur),
          bonus: formatSignedVisible(skillBonus),
          raceBonus: formatSignedVisible(skillRaceBonus),
          final: hasOwnContribution ? String(base) : '',
        } satisfies ValueCells;
      })(),
    });
    skillSidebarGrouped.set(key, sidebarArr);
  }
  const skillTables: Table[] = ['INT','REF','DEX','BODY','SPD','EMP','CRA','WILL','OTHER']
    .map((key) => {
      const rows = (grouped.get(key) ?? []).sort((a, b) => (a.cells[0] ?? '').localeCompare(b.cells[0] ?? '', lang === 'ru' ? 'ru' : 'en'));
      if (!rows.length) return null;
      const statLabel = key === 'OTHER' ? 'OTHER' : `${key} ${statValue(asRecord(stats[key])).full}`;
      return { title: statLabel, columns: [tx.cols.n, tx.cols.v], rows };
    })
    .filter((t): t is Table => Boolean(t));

  const prof = asRecord(asRecord(resolved.skills)?.professional) ?? {};
  const branchNames = asArray(prof.branches).map((x) => text(x, '')).filter(Boolean);
  const profRows: Row[] = [];
  for (let b = 1; b <= 3; b += 1) {
    for (let s = 1; s <= 3; s += 1) {
      const rec = asRecord(prof[`skill_${b}_${s}`]);
      const name = text(rec?.name ?? rec?.label ?? rec?.id, '');
      if (name) profRows.push({ cells: [branchNames[b - 1] || `Branch ${b}`, name] });
    }
  }
  const profTable: Table = { title: tx.sections.prof, columns: [lang === 'ru' ? 'Ветка' : 'Branch', tx.cols.n], rows: profRows.length ? profRows : [{ cells: ['—', '—'] }] };
  const profBranches: ProfBranch[] = (['blue', 'mint', 'rose'] as const).map((color, idx) => {
    const rows: ProfBranchRow[] = [];
    for (let slot = 1; slot <= 3; slot += 1) {
      const rec = asRecord(prof[`skill_${idx + 1}_${slot}`]);
      const id = typeof rec?.id === 'string' ? rec.id : '';
      const catalog = id ? skillsCatalogById?.get(id) : undefined;
      const name = text(rec?.name ?? rec?.label ?? catalog?.name ?? rec?.id, '');
      const paramId = (catalog?.param || (typeof rec?.param === 'string' ? rec.param : '') || '').toUpperCase();
      const paramAbbr = (tx.statsAbbr as Record<string, string>)[paramId] ?? '';
      if (name) rows.push({ name, paramAbbr });
    }
    return {
      title: branchNames[idx] || `${lang === 'ru' ? 'Ветка' : 'Branch'} ${idx + 1}`,
      color,
      rows,
    };
  });

  const skillSidebarGroups: SkillSidebarGroup[] = ['INT','REF','DEX','BODY','SPD','EMP','CRA','WILL','OTHER']
    .map((id) => {
      const rows = (skillSidebarGrouped.get(id) ?? []).sort((a, b) => a.name.localeCompare(b.name, lang === 'ru' ? 'ru' : 'en'));
      if (!rows.length) return null;
      const statCells = id === 'OTHER'
        ? { cur: '', bonus: '', raceBonus: '', final: '' }
        : valueCellsFromStatish(asRecord(rawStats[id]));
      const full = (tx.statsFull as Record<string, string>)[id] ?? id;
      return { statId: id, title: full, statCells, rows } satisfies SkillSidebarGroup;
    })
    .filter((g): g is SkillSidebarGroup => Boolean(g));

  const perksTable: Table = {
    title: tx.sections.perks,
    columns: [lang === 'ru' ? 'ПЕРК' : 'PERK', tx.cols.effect],
    rows: asArray(resolved.perks).map((p) => {
      const s = text(p, '');
      const i = s.indexOf(':');
      return i >= 0 ? { cells: [s.slice(0, i).trim(), s.slice(i + 1).trim()] } : { cells: [s || '—', ''] };
    }),
  };
  if (!perksTable.rows.length) perksTable.rows.push({ cells: ['—', '—'] });

  const gear = asRecord(resolved.gear) ?? {};
  const makeItemName = (rec: Record<string, unknown>) => text(rec.name ?? rec.weapon_name ?? rec.armor_name ?? rec.potion_name ?? rec.spell_name ?? rec.invocation_name ?? rec.gift_name ?? rec.w_id ?? rec.a_id ?? rec.p_id);
  const weapons = asArray(gear.weapons).map((x) => asRecord(x) ?? {}).map((r) => ({
    cells: [
      text(r.amount ?? r.qty ?? r.quantity, ''),
      makeItemName(r),
      text(r.dmg),
      text(r.dmg_types ?? r.type),
      text(r.reliability),
      text(r.hands),
      text(r.concealment ?? r.conceal),
      text(r.enhancements ?? r.enhancement ?? r.upgrades),
      text(r.weight),
      text(r.price),
      text(r.effect_names ?? r.effect ?? r.note ?? r.special, ''),
    ],
  }));
  const armors = asArray(gear.armors).map((x) => asRecord(x) ?? {}).map((r) => ({
    cells: [
      text(r.amount ?? r.qty ?? r.quantity, ''),
      makeItemName(r),
      text(r.stopping_power ?? r.sp),
      text(r.encumbrance ?? r.enc),
      text(r.enhancements ?? r.enhancement ?? r.upgrades),
      text(r.weight),
      text(r.price),
      text(r.effect_names ?? r.effect ?? r.note ?? r.special, ''),
    ],
  }));
  const potions = asArray(gear.potions).map((x) => asRecord(x) ?? {}).map((r) => ({ cells: [text(r.amount ?? r.qty ?? r.quantity, ''), makeItemName(r), text(r.toxicity), text(r.time_effect ?? r.duration), text(r.effect), text(r.weight), text(r.price)] }));
  const recipes: RecipePageRow[] = asArray(gear.recipes)
    .map((x) => asRecord(x) ?? {})
    .map((r) => ({
      amount: text(r.amount ?? r.qty ?? r.quantity, ''),
      recipeGroup: text(r.recipe_group, ''),
      recipeName: text(r.recipe_name ?? r.name, ''),
      complexity: text(r.complexity, ''),
      timeCraft: text(r.time_craft, ''),
      formulaEn: text(r.formula_en, ''),
      priceFormula: text(r.price_formula, ''),
      minimalIngredientsCost: text(r.minimal_ingredients_cost, ''),
      timeEffect: text(r.time_effect, ''),
      toxicity: text(r.toxicity, ''),
      recipeDescription: text(r.recipe_description ?? r.effect, ''),
      weightPotion: text(r.weight_potion, ''),
      pricePotion: text(r.price_potion, ''),
    }))
    .filter((r) =>
      r.amount || r.recipeGroup || r.recipeName || r.complexity || r.timeCraft || r.formulaEn || r.priceFormula ||
      r.minimalIngredientsCost || r.timeEffect || r.toxicity || r.recipeDescription || r.weightPotion || r.pricePotion,
    );
  const blueprints: BlueprintPageRow[] = asArray(gear.blueprints)
    .map((x) => asRecord(x) ?? {})
    .map((b) => ({
      amount: text(b.amount ?? b.qty ?? b.quantity, '1'),
      name: text(b.blueprint_name ?? b.name ?? b.b_id, ''),
      group: text(b.blueprint_group ?? b.group, ''),
      craftLevel: text(b.craft_level, ''),
      difficultyCheck: text(b.difficulty_check, ''),
      timeCraft: text(b.time_craft, ''),
      components: text(b.components, ''),
      itemDesc: text(b.item_desc ?? b.description, ''),
      priceComponents: text(b.price_components, ''),
      price: text(b.price, ''),
      priceItem: text(b.price_item, ''),
    }))
    .filter((b) =>
      b.amount || b.name || b.group || b.craftLevel || b.difficultyCheck || b.timeCraft ||
      b.components || b.itemDesc || b.priceComponents || b.price || b.priceItem,
    );

  const ingredients = asRecord(gear.ingredients) ?? {};
  const componentRowsAll: ComponentPageRow[] = [...asArray(ingredients.alchemy), ...asArray(ingredients.craft)]
    .map((x) => asRecord(x) ?? {})
    .map((i) => ({
      amount: text(i.amount ?? i.qty ?? i.quantity, '1'),
      substanceEn: text(i.alchemy_substance_en, ''),
      name: text(i.ingredient_name ?? i.name ?? i.i_id, ''),
      harvestingComplexity: text(i.harvesting_complexity, ''),
      weight: text(i.weight, ''),
      price: text(i.price, ''),
    }))
    .filter((r) => r.amount || r.substanceEn || r.name || r.harvestingComplexity || r.weight || r.price);
  const componentRowsByTable: [ComponentPageRow[], ComponentPageRow[], ComponentPageRow[]] = [[], [], []];
  for (let i = 0; i < componentRowsAll.length; i += 1) {
    componentRowsByTable[i % 3]!.push(componentRowsAll[i]!);
  }
  const page3ComponentTables = componentRowsByTable.map((rows) => ({ rows: rows.slice() }));
  const vehicles: VehiclePageRow[] = asArray(gear.vehicles)
    .map((x) => asRecord(x) ?? {})
    .map((v) => ({
      amount: text(v.amount ?? v.qty ?? v.quantity, '1'),
      subgroupName: text(v.subgroup_name, ''),
      vehicleName: text(v.vehicle_name ?? v.name ?? v.wt_id, ''),
      base: text(v.base, ''),
      controlModifier: text(v.control_modifier, ''),
      speed: text(v.speed, ''),
      hp: text(v.hp, ''),
      weight: text(v.weight, ''),
      price: text(v.price, ''),
      occupancy: text(v.occupancy, ''),
    }))
    .filter((v) =>
      v.amount || v.subgroupName || v.vehicleName || v.base || v.controlModifier || v.speed || v.hp || v.weight || v.price || v.occupancy,
    );
  const moneyRoot = asRecord(raw.money) ?? asRecord(resolved.money) ?? {};
  const page3Money = {
    crowns: text(moneyRoot.crowns, ''),
    orens: '',
    florens: '',
    ducats: '',
    bizants: '',
    lintars: '',
  };
  const page3GeneralGear: GeneralGearPageRow[] = asArray(gear.general_gear)
    .map((x) => asRecord(x) ?? {})
    .map((g) => ({
      amount: text(g.amount ?? g.qty ?? g.quantity, '1'),
      name: text(g.name ?? g.gear_name ?? g.t_id, ''),
      description: text(g.description ?? g.gear_description, ''),
      concealment: text(g.concealment, ''),
      weight: text(g.weight, ''),
      price: text(g.price, ''),
    }))
    .filter((g) => g.amount || g.name || g.description || g.concealment || g.weight || g.price);

  const magic = asRecord(gear.magic) ?? {};
  const rawGear = asRecord(raw.gear) ?? {};
  const rawMagic = asRecord(rawGear.magic) ?? {};

  const mergeMagicRowsByIndex = (resolvedList: unknown[], rawList: unknown[]): Array<Record<string, unknown>> => {
    const len = Math.max(resolvedList.length, rawList.length);
    const out: Array<Record<string, unknown>> = [];
    for (let i = 0; i < len; i += 1) {
      const merged = {
        ...(asRecord(rawList[i]) ?? {}),
        ...(asRecord(resolvedList[i]) ?? {}),
      };
      if (Object.keys(merged).length > 0) out.push(merged);
    }
    return out;
  };
  const toSortKey = (value: unknown): number => {
    const parsed = Number(String(value ?? '').trim());
    return Number.isFinite(parsed) ? parsed : Number.POSITIVE_INFINITY;
  };
  const compareByName = (a: { name: string }, b: { name: string }) =>
    a.name.localeCompare(b.name, lang === 'ru' ? 'ru' : 'en', { sensitivity: 'base' });
  const lowerProfession = [
    text(raw.profession, ''),
    text(resolved.profession, ''),
    text(logic.profession, ''),
    text(logic.profession_code, ''),
  ]
    .join(' ')
    .toLowerCase();
  const isMage = containsAnyNeedle(lowerProfession, ['mage', 'маг']);
  const isWitcherProfession = containsAnyNeedle(lowerProfession, ['witcher', 'ведьмак', 'ведьмач']);
  const isDruid = containsAnyNeedle(lowerProfession, ['druid', 'друид']);
  const isPriest = containsAnyNeedle(lowerProfession, ['priest', 'жрец']) || isDruid;
  const vigorRec = asRecord(rawStats.vigor ?? rawStats.VIGOR ?? stats.vigor ?? stats.VIGOR) ?? {};
  const hasVigor =
    (num(vigorRec.cur) ?? 0) +
      (num(vigorRec.bonus ?? vigorRec.mod) ?? 0) +
      (num(vigorRec.race_bonus) ?? 0) >
    0;

  const spellsMerged = mergeMagicRowsByIndex(asArray(magic.spells), asArray(rawMagic.spells));
  const signsMerged = mergeMagicRowsByIndex(asArray(magic.signs), asArray(rawMagic.signs));
  const spellsSignsRows: MagicSpellLikeRow[] = [...spellsMerged, ...signsMerged]
    .map((rec) => {
      const name = text(rec.spell_name ?? rec.name, '').trim();
      if (!name) return null;
      return {
        name,
        element: text(rec.element, ''),
        staminaCast: text(rec.stamina_cast, ''),
        staminaKeeping: text(rec.stamina_keeping, ''),
        damage: text(rec.damage, ''),
        distance: text(rec.distance, ''),
        zoneSize: text(rec.zone_size, ''),
        form: text(rec.form, ''),
        effectTime: text(rec.effect_time, ''),
        tooltip: text(rec.effect ?? rec.tooltip, ''),
        _sort: toSortKey(rec.sort_key),
      };
    })
    .filter((v): v is (MagicSpellLikeRow & { _sort: number }) => Boolean(v))
    .sort((a, b) => (a._sort - b._sort) || compareByName(a, b))
    .map(({ _sort, ...rest }) => rest);

  const resolvedInv = asRecord(magic.invocations) ?? {};
  const rawInv = asRecord(rawMagic.invocations) ?? {};
  const invocationsMerged = [
    ...mergeMagicRowsByIndex(asArray(resolvedInv.druid), asArray(rawInv.druid)),
    ...mergeMagicRowsByIndex(asArray(resolvedInv.priest), asArray(rawInv.priest)),
  ];
  const invocationsRows: MagicInvocationRow[] = invocationsMerged
    .map((rec) => {
      const name = text(rec.invocation_name ?? rec.name, '').trim();
      if (!name) return null;
      return {
        name,
        group: text(rec.cult_or_circle ?? rec.group, ''),
        staminaCast: text(rec.stamina_cast, ''),
        staminaKeeping: text(rec.stamina_keeping, ''),
        damage: text(rec.damage, ''),
        distance: text(rec.distance, ''),
        zoneSize: text(rec.zone_size, ''),
        form: text(rec.form, ''),
        effectTime: text(rec.effect_time, ''),
        tooltip: text(rec.effect ?? rec.tooltip, ''),
      };
    })
    .filter((v): v is MagicInvocationRow => Boolean(v))
    .sort(compareByName);

  const magicRows: Row[] = [];
  const pushMagicSummary = (list: Array<Record<string, unknown>>, typeLabel: string, elementKey: 'element' | 'cult_or_circle') => {
    list.forEach((rec) => {
      const name = text(rec.spell_name ?? rec.invocation_name ?? rec.name, '').trim();
      if (!name) return;
      magicRows.push({
        cells: [
          typeLabel,
          name,
          text(rec[elementKey], ''),
          text(rec.stamina_cast ?? rec.vigor_cost ?? rec.cost, ''),
          text(rec.stamina_keeping, ''),
          text(rec.damage, ''),
          text(rec.effect_time ?? rec.duration, ''),
          text(rec.distance ?? rec.range, ''),
          text(rec.zone_size, ''),
          text(rec.form ?? rec.note, ''),
        ],
      });
    });
  };
  const spellsSummary = spellsMerged.map((rec) => ({
    typeLabel:
      text(rec.type, '').trim().toLowerCase() === 'sign'
        ? tx.page1.magicTypes.sign
        : tx.page1.magicTypes.spell,
    rec,
  }));
  spellsSummary.forEach(({ rec, typeLabel }) => pushMagicSummary([rec], typeLabel, 'element'));
  pushMagicSummary(signsMerged, tx.page1.magicTypes.sign, 'element');
  pushMagicSummary(invocationsMerged, tx.page1.magicTypes.invocation, 'cult_or_circle');

  const ritualsMerged = mergeMagicRowsByIndex(asArray(magic.rituals), asArray(rawMagic.rituals));
  const ritualsRows: MagicRitualRow[] = ritualsMerged
    .map((rec) => {
      const name = text(rec.ritual_name ?? rec.name, '').trim();
      if (!name) return null;
      return {
        name,
        level: text(rec.level, ''),
        dc: text(rec.dc, ''),
        preparingTime: text(rec.preparing_time, ''),
        staminaCast: text(rec.stamina_cast, ''),
        staminaKeeping: text(rec.stamina_keeping, ''),
        zoneSize: text(rec.zone_size, ''),
        form: text(rec.form, ''),
        effectTime: text(rec.effect_time, ''),
        ingredients: normalizeComponentsMultiline(text(rec.ingredients, '')),
        tooltip: stripRitualComponentsFromEffect(text(rec.effect ?? rec.tooltip ?? rec.effect_tpl, '')),
        _sort: toSortKey(rec.sort_key),
      };
    })
    .filter((v): v is (MagicRitualRow & { _sort: number }) => Boolean(v))
    .sort((a, b) => (a._sort - b._sort) || compareByName(a, b))
    .map(({ _sort, ...rest }) => rest);

  const hexesMerged = mergeMagicRowsByIndex(asArray(magic.hexes), asArray(rawMagic.hexes));
  const hexesRows: MagicHexRow[] = hexesMerged
    .map((rec) => {
      const name = text(rec.hex_name ?? rec.name, '').trim();
      if (!name) return null;
      return {
        name,
        level: text(rec.level, ''),
        staminaCast: text(rec.stamina_cast, ''),
        removeComponents: normalizeComponentsMultiline(text(rec.remove_components, '')),
        removeInstructions: text(rec.remove_instructions, ''),
        tooltip: text(rec.effect ?? rec.tooltip, ''),
        _sort: toSortKey(rec.sort_key),
      };
    })
    .filter((v): v is (MagicHexRow & { _sort: number }) => Boolean(v))
    .sort((a, b) => (a._sort - b._sort) || compareByName(a, b))
    .map(({ _sort, ...rest }) => rest);

  const giftsMerged = mergeMagicRowsByIndex(asArray(magic.gifts), asArray(rawMagic.gifts));
  const giftsRows: MagicGiftRow[] = giftsMerged
    .map((rec) => {
      const id = text(rec.mg_id ?? rec.id, '').trim();
      const name = text(rec.gift_name ?? rec.name, '').trim() || id;
      if (!name) return null;
      const isMajor =
        rec.is_major === true ||
        String(rec.is_major ?? '')
          .trim()
          .toLowerCase() === 'true';
      const actionCost = text(rec.action_cost, '').trim();
      return {
        name,
        group: text(rec.group_name ?? rec.group, ''),
        sl: text(rec.dc, ''),
        vigor: text(rec.vigor_cost, ''),
        cost: actionCost || (isMajor ? tx.page4.gifts.costFullAction : tx.page4.gifts.costAction),
        description: text(rec.description, ''),
        _sort: text(rec.sort_key, ''),
      };
    })
    .filter((v): v is (MagicGiftRow & { _sort: string }) => Boolean(v))
    .sort((a, b) => (a._sort || a.group).localeCompare(b._sort || b.group, lang === 'ru' ? 'ru' : 'en', { sensitivity: 'base' }))
    .map(({ _sort, ...rest }) => rest);

  const onlyGiftsMagic =
    giftsRows.length > 0 &&
    spellsSignsRows.length === 0 &&
    invocationsRows.length === 0 &&
    ritualsRows.length === 0 &&
    hexesRows.length === 0;
  const showSpellsSigns = onlyGiftsMagic ? false : spellsSignsRows.length > 0 || isMage || isWitcherProfession;
  const showInvocations = onlyGiftsMagic ? false : invocationsRows.length > 0 || isPriest;
  const showRituals = onlyGiftsMagic ? false : ritualsRows.length > 0 || hasVigor;
  const showHexes = onlyGiftsMagic ? false : hexesRows.length > 0 || hasVigor;
  const showGifts = giftsRows.length > 0;
  const canRenderSpellsSigns = showSpellsSigns && (spellsSignsRows.length > 0 || pdfTableSettings.spellsSigns.showIfEmpty);
  const canRenderInvocations = showInvocations && (invocationsRows.length > 0 || pdfTableSettings.invocations.showIfEmpty);
  const canRenderRituals = showRituals && (ritualsRows.length > 0 || pdfTableSettings.rituals.showIfEmpty);
  const canRenderHexes = showHexes && (hexesRows.length > 0 || pdfTableSettings.hexes.showIfEmpty);
  const page4Magic: MagicPageVm = {
    onlyGiftsMagic,
    shouldRender: canRenderSpellsSigns || canRenderInvocations || canRenderRituals || canRenderHexes || showGifts,
    showSpellsSigns,
    showInvocations,
    showRituals,
    showHexes,
    showGifts,
    invocationsTitle: isDruid ? tx.page4.titles.invocationsDruid : tx.page4.titles.invocationsPriest,
    invocationsFill: isDruid ? COLORS.headerMagicInvDruid : COLORS.headerMagicInvPriest,
    spellsSignsRows,
    invocationsRows,
    ritualsRows,
    hexesRows,
    giftsRows,
  };

  const lore = asRecord(resolved.lore);
  const loreRows: Row[] = [];
  const addLore = (label: string, v: unknown) => { const s = text(v, ''); if (s) loreRows.push({ cells: [label, s] }); };
  if (lore) {
    addLore(lang === 'ru' ? 'Родина' : 'Homeland', lore.homeland);
    addLore(lang === 'ru' ? 'Семья' : 'Family', lore.family_fate);
    addLore(lang === 'ru' ? 'Родители' : 'Parents', lore.parents_fate);
    addLore(lang === 'ru' ? 'Друг' : 'Friend', lore.friend);
  }
  const joinArr = (label: string, v: unknown) => { const arr = asArray(v).map((x) => text(x, '')).filter(Boolean); if (arr.length) loreRows.push({ cells: [label, arr.join(' | ')] }); };
  joinArr(lang === 'ru' ? 'Союзники' : 'Allies', resolved.allies);
  joinArr(lang === 'ru' ? 'Соц. статус' : 'Social status', resolved.social_status);

  const loreBlocks: LoreBlock[] = [];
  const pushLore = (label: string, value: unknown) => {
    const v = text(value, '').trim();
    if (!v) return;
    loreBlocks.push({ label, value: v });
  };
  if (lore) {
    pushLore(tx.page2.loreLabels.homeland, lore.homeland);
    pushLore(tx.page2.loreLabels.homeLanguage, lore.home_language);
    pushLore(tx.page2.loreLabels.familyStatus, lore.family_status);
    pushLore(tx.page2.loreLabels.familyFate, lore.family_fate);
    const parentsWho = text(lore.parents_fate_who, '').trim();
    const parentsFate = text(lore.parents_fate, '').trim();
    if (parentsWho || parentsFate) {
      pushLore(tx.page2.loreLabels.parentsFate, parentsWho ? `${parentsWho}. ${parentsFate}`.trim() : parentsFate);
    }
    pushLore(tx.page2.loreLabels.friend, lore.friend);
    pushLore(tx.page2.loreLabels.school, lore.school);
    pushLore(tx.page2.loreLabels.initiation, lore.witcher_initiation_moment);
    const diseases = Array.isArray(lore.diseases_and_curses)
      ? lore.diseases_and_curses.map(formatDiseaseOrCurseEntry).map((v) => v.trim()).filter(Boolean).join('\n')
      : formatDiseaseOrCurseEntry(lore.diseases_and_curses);
    pushLore(tx.page2.loreLabels.diseases, diseases);
    pushLore(tx.page2.loreLabels.importantEvent, lore.most_important_event);
    pushLore(tx.page2.loreLabels.trainings, lore.trainings);
    pushLore(tx.page2.loreLabels.currentSituation, lore.current_situation);
  }

  const styleRec = asRecord(lore?.style);
  const styleTableVm: StyleTableVm = {
    clothing: text(styleRec?.clothing, ''),
    personality: text(styleRec?.personality, ''),
    hairStyle: text(styleRec?.hair_style, ''),
    affectations: text(styleRec?.affectations, ''),
  };
  const valuesRec = asRecord(lore?.values);
  const valuesTableVm: ValuesTableVm = {
    valuedPerson: text(valuesRec?.valued_person, ''),
    value: text(valuesRec?.value, ''),
    feelingsOnPeople: text(valuesRec?.feelings_on_people, ''),
  };

  const socialStatusRaw = Array.isArray(resolved.social_status) ? resolved.social_status : [];
  const socialStatusGroups: SocialStatusGroup[] = socialStatusRaw
    .map((s) => asRecord(s) ?? {})
    .map((rec) => {
      const groupName = text(rec.group_name, '');
      const st = num(rec.group_status);
      const isFeared = rec.group_is_feared === true || String(rec.group_is_feared) === 'true';
      const statusLabel =
        st === 1
          ? tx.page2.socialStatus.hated
          : st === 2
            ? tx.page2.socialStatus.tolerated
            : tx.page2.socialStatus.equal;
      return { groupName, statusLabel, isFeared };
    })
    .filter((g) => g.groupName.length > 0);

  const lifeEvents: LifeEventRow[] = Array.isArray(lore?.lifeEvents)
    ? lore.lifeEvents
        .map((e) => asRecord(e) ?? {})
        .map((rec) => ({
          period: text(rec.timePeriod, ''),
          type: text(rec.eventType, ''),
          description: text(rec.description, ''),
        }))
        .filter((r) => r.period || r.type || r.description)
    : [];
  const siblings: SiblingRow[] = Array.isArray(lore?.siblings)
    ? lore.siblings
        .map((s) => asRecord(s) ?? {})
        .map((rec) => ({
          age: text(rec.age, ''),
          gender: text(rec.gender, ''),
          attitude: text(rec.attitude, ''),
          personality: text(rec.personality, ''),
        }))
        .filter((r) => r.age || r.gender || r.attitude || r.personality)
    : [];

  const isWitcher = text(logic.race, '').trim().toLowerCase() === 'witcher';
  const allies: AllyRow[] = asArray(resolved.allies)
    .map((a) => asRecord(a) ?? {})
    .map((rec) => {
      const alive = text(rec.is_alive, '');
      const deathReason = text(rec.death_reason, '');
      return {
        gender: text(rec.gender, ''),
        position: text(rec.position, ''),
        where: text(rec.where, ''),
        howMet: text(rec.how_met, ''),
        howClose: text(rec.how_close, ''),
        isAlive: deathReason ? `${alive} - ${deathReason}` : alive,
      };
    })
    .filter((a) => a.gender || a.position || a.where || a.howMet || a.howClose || a.isAlive);
  const enemies: EnemyVmRow[] = asArray(resolved.enemies)
    .map((e) => asRecord(e) ?? {})
    .map((rec) => {
      if (isWitcher) {
        const alive = text(rec.is_alive, '');
        const deathReason = text(rec.death_reason, '');
        return {
          gender: text(rec.gender, ''),
          position: text(rec.position, ''),
          victim: '',
          cause: text(rec.the_cause, ''),
          power: text(rec.power, ''),
          level: '',
          result: text(rec.escalation_level, ''),
          alive: deathReason ? `${alive} - ${deathReason}` : alive,
        };
      }
      return {
        gender: text(rec.gender, ''),
        position: text(rec.position, ''),
        victim: text(rec.victim, ''),
        cause: text(rec.cause, ''),
        power: text(rec.the_power, ''),
        level: text(rec.power_level, ''),
        result: text(rec.how_far, ''),
        alive: '',
      };
    })
    .filter((e) => e.gender || e.position || e.victim || e.cause || e.power || e.level || e.result || e.alive);

  return {
    lang, tx, title: tx.title, subtitle: tx.subtitle, baseRows, mainStats, extraStats, consRows, skillTables, profTable, perksTable,
    alchemyIconStyle,
    pdfTableSettings,
    definingSkillLine: definingCalc.skillLine,
    definingCells: definingCalc.cells,
    definingBasis: definingCalc.basis,
    skillSidebarGroups,
    profBranches,
    weaponsTable: weapons.length ? { title: tx.sections.weapons, columns: [' ', tx.cols.qty, tx.sections.weapons, tx.cols.dmg, tx.cols.type, tx.cols.rel, tx.cols.hands, tx.cols.conceal, tx.cols.enh, tx.cols.wt, tx.cols.price], rows: weapons } : null,
    armorTable: armors.length ? { title: tx.sections.armor, columns: [' ', tx.cols.qty, tx.sections.armor, lang === 'ru' ? 'ПБ/Н' : 'SP', tx.cols.enc, lang === 'ru' ? 'УБ' : 'ENH', tx.cols.wt, tx.cols.price], rows: armors } : null,
    potionTable: potions.length ? { title: tx.sections.alchemy, columns: [tx.cols.qty, tx.cols.n, tx.cols.tox, tx.cols.time, tx.cols.effect, tx.cols.wt, tx.cols.price], rows: potions } : null,
    magicTable: magicRows.length
      ? {
          title: tx.sections.magic,
          columns: [
            tx.page1.magicCols.type,
            tx.page1.magicCols.name,
            tx.page1.magicCols.element,
            tx.page1.magicCols.vigor,
            tx.page1.magicCols.vigorKeep,
            tx.page1.magicCols.damage,
            tx.page1.magicCols.time,
            tx.page1.magicCols.distance,
            tx.page1.magicCols.size,
            tx.page1.magicCols.form,
          ],
          rows: magicRows,
        }
      : null,
    loreTable: loreRows.length ? { title: tx.sections.lore, columns: [tx.cols.field, tx.cols.note], rows: loreRows } : null,
    page2SocialStatus: socialStatusGroups,
    page2LoreBlocks: loreBlocks,
    page2StyleTable: styleTableVm,
    page2ValuesTable: valuesTableVm,
    page2LifeEvents: lifeEvents,
    page2Siblings: siblings,
    page2Allies: allies,
    page2Enemies: enemies,
    page2IsWitcher: isWitcher,
    page2ItemEffects: Array.isArray(itemEffectsGlossary) ? [...itemEffectsGlossary] : [],
    page3Recipes: recipes,
    page3Blueprints: blueprints,
    page3ComponentTables,
    page3Vehicles: vehicles,
    page3Money,
    page3GeneralGear,
    page4Magic,
  };
}

function calcResolve(stats: Record<string, unknown>): string {
  const w = num(asRecord(stats.WILL)?.cur) ?? 0;
  const i = num(asRecord(stats.INT)?.cur) ?? 0;
  return String(Math.floor((5 * (w + i)) / 2));
}

function calcDefiningBase(params: {
  statistics: Record<string, unknown>;
  skillsCommon: Record<string, unknown>;
  defining: Record<string, unknown> | null;
  statAbbr: Record<string, string>;
  baseWord: string;
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>;
}): { skillLine: string; rightLine: string; basis: string } {
  const { statistics, skillsCommon, defining } = params;
  if (!defining) return { skillLine: '—', rightLine: '', basis: '' };
  const skillId = typeof defining.id === 'string' ? defining.id : '';
  const skillName = text(defining.name ?? defining.label ?? defining.id, '—');
  const skillRec = asRecord(skillId ? skillsCommon[skillId] : null) ?? {};
  const catalogParam = params.skillsCatalogById?.get(skillId)?.param ?? null;
  const normalizedParam =
    typeof catalogParam === 'string' && catalogParam.trim()
      ? catalogParam.trim().toUpperCase()
      : skillId.startsWith('language_')
        ? 'INT'
        : (SKILL_TO_STAT[skillId] ?? '').toUpperCase();
  const statId = normalizedParam;
  const statRec = asRecord(statId ? statistics[statId] : null) ?? {};
  const skillVal = statValue(skillRec).full;
  if (!statId) return { skillLine: `${skillName} ${skillVal}`.trim(), rightLine: '', basis: '' };

  const statCur = num(statRec.cur) ?? 0;
  const statBonus = num(statRec.bonus ?? statRec.mod) ?? 0;
  const statRaceBonus = num(statRec.race_bonus) ?? 0;
  const skillCur = num(skillRec.cur) ?? 0;
  const skillBonus = num(skillRec.bonus ?? skillRec.mod) ?? 0;
  const skillRaceBonus = num(skillRec.race_bonus) ?? 0;

  const basis =
    calcStatFinal(statCur, statBonus, statRaceBonus) +
    calcSkillContribution(skillCur, skillBonus, skillRaceBonus);

  const fmt = (n: number) => (n > 0 ? `+${n}` : `${n}`);
  const statAbbr = params.statAbbr[statId] ?? statId;
  const compact = [
    String(skillCur),
    fmt(skillBonus),
    fmt(skillRaceBonus),
    `${params.baseWord} ${basis}`,
  ].join('  ');
  return {
    skillLine: `${skillName} (${statAbbr})`,
    rightLine: compact,
    basis: String(basis),
  };
}

function calcDefiningDisplay(params: {
  statistics: Record<string, unknown>;
  skillsCommon: Record<string, unknown>;
  defining: Record<string, unknown> | null;
  statAbbr: Record<string, string>;
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>;
}): DefiningDisplay {
  const { statistics, skillsCommon, defining } = params;
  if (!defining) {
    return { skillLine: '—', basis: '', cells: { skillCur: '', skillBonus: '', skillRaceBonus: '', basis: '' } };
  }
  const skillId = typeof defining.id === 'string' ? defining.id : '';
  const skillName = text(defining.name ?? defining.label ?? defining.id, '—');
  const skillRec = asRecord(skillId ? skillsCommon[skillId] : null) ?? {};
  const catalogParam = params.skillsCatalogById?.get(skillId)?.param ?? null;
  const statId =
    (typeof catalogParam === 'string' && catalogParam.trim()
      ? catalogParam.trim().toUpperCase()
      : skillId.startsWith('language_')
        ? 'INT'
        : (SKILL_TO_STAT[skillId] ?? '').toUpperCase());
  const statRec = asRecord(statId ? statistics[statId] : null) ?? {};
  const statAbbr = params.statAbbr[statId] ?? statId;

  const statCur = num(statRec.cur) ?? 0;
  const statBonus = num(statRec.bonus ?? statRec.mod) ?? 0;
  const statRaceBonus = num(statRec.race_bonus) ?? 0;
  const skillCur = num(skillRec.cur) ?? 0;
  const skillBonus = num(skillRec.bonus ?? skillRec.mod) ?? 0;
  const skillRaceBonus = num(skillRec.race_bonus) ?? 0;
  const basis =
    calcStatFinal(statCur, statBonus, statRaceBonus) +
    calcSkillContribution(skillCur, skillBonus, skillRaceBonus);
  const fmtSigned = (n: number) => (n > 0 ? `+${n}` : `${n}`);
  const visibleIfNonZero = (n: number) => (n === 0 ? '' : fmtSigned(n));
  return {
    skillLine: statId ? `${skillName} (${statAbbr})` : skillName,
    basis: String(basis),
    cells: {
      skillCur: skillCur === 0 ? '' : String(skillCur),
      skillBonus: visibleIfNonZero(skillBonus),
      skillRaceBonus: visibleIfNonZero(skillRaceBonus),
      basis: String(basis),
    },
  };
}

function sumWeight(resolved: Record<string, unknown>): string {
  const gear = asRecord(resolved.gear); if (!gear) return '';
  let total = 0; let seen = false;
  const walk = (v: unknown): void => {
    if (Array.isArray(v)) return v.forEach(walk);
    const r = asRecord(v); if (!r) return;
    const w = num(r.weight); if (w != null) { total += w * (num(r.amount ?? r.qty ?? r.quantity) ?? 1); seen = true; }
    Object.values(r).forEach(walk);
  };
  walk(gear);
  return seen ? total.toFixed(1) : '';
}

function formatSignedVisible(n: number): string {
  if (n === 0) return '';
  return n > 0 ? `+${n}` : `${n}`;
}

function clamp(n: number, minValue: number, maxValue: number): number {
  return Math.min(Math.max(n, minValue), maxValue);
}

function calcStatFinal(cur: number, bonus: number, raceBonus: number): number {
  return Math.max(1, Math.min(cur + bonus, 10) + raceBonus);
}

function calcSkillContribution(cur: number, bonus: number, raceBonus: number): number {
  return Math.max(0, Math.min(cur + bonus, 10) + raceBonus);
}

function formatStatHeaderExpression(cells: ValueCells): string {
  const cur = cells.cur.trim();
  const bonus = cells.bonus.trim();
  const race = cells.raceBonus.trim();
  const final = cells.final.trim();
  if (!cur && !final) return '';
  if (!bonus && !race) return final || cur;
  return `${cur}${bonus}${race} = ${final || cur}`;
}

function valueCellsFromStatish(rec: Record<string, unknown> | null): ValueCells {
  const r = rec ?? {};
  const cur = num(r.cur ?? r.value ?? r.total) ?? 0;
  const bonus = num(r.bonus ?? r.mod) ?? 0;
  const raceBonus = num(r.race_bonus) ?? 0;
  const final = calcStatFinal(cur, bonus, raceBonus);
  return {
    cur: cur === 0 ? '' : String(cur),
    bonus: formatSignedVisible(bonus),
    raceBonus: formatSignedVisible(raceBonus),
    final: String(final),
  };
}

type FractionalGroup = '1/2' | '1/3' | '1/4';
type PackedPlacement = { itemIndex: number; col: number; y: number; h: number };

function moveIndexOrder(order: number[], from: number, to: number): number[] {
  if (from === to) return order.slice();
  const next = order.slice();
  const [item] = next.splice(from, 1);
  next.splice(to, 0, item!);
  return next;
}

function enumerateOrdersWithMoves(baseOrder: number[], maxMoves: number): number[][] {
  const seen = new Set<string>();
  const out: number[][] = [];
  const add = (ord: number[]) => {
    const key = ord.join(',');
    if (seen.has(key)) return;
    seen.add(key);
    out.push(ord);
  };
  add(baseOrder.slice());

  if (maxMoves <= 0) return out;

  const oneMove: number[][] = [];
  for (let from = 0; from < baseOrder.length; from += 1) {
    for (let to = 0; to < baseOrder.length; to += 1) {
      if (from === to) continue;
      const ord = moveIndexOrder(baseOrder, from, to);
      add(ord);
      oneMove.push(ord);
    }
  }

  if (maxMoves <= 1) return out;

  for (const ord of oneMove) {
    for (let from = 0; from < ord.length; from += 1) {
      for (let to = 0; to < ord.length; to += 1) {
        if (from === to) continue;
        add(moveIndexOrder(ord, from, to));
      }
    }
  }
  return out;
}

class Painter {
  private doc: PDFKit.PDFDocument;
  private x: number;
  private w: number;
  private y: number;
  private page3FirstPairGuideRows: number;
  constructor(doc: PDFKit.PDFDocument) {
    this.doc = doc;
    this.x = PAGE.margin;
    this.w = doc.page.width - PAGE.margin * 2;
    this.y = PAGE.margin;
    this.page3FirstPairGuideRows = 0;
    const fp = fontPaths();
    doc.registerFont(FONTS.regular, fp.regular);
    doc.registerFont(FONTS.bold, fp.bold);
    this.paintBg();
  }
  private paintBg() { this.doc.rect(0, 0, this.doc.page.width, this.doc.page.height).fill(COLORS.page); }
  private bottom() { return this.doc.page.height - PAGE.margin; }
  private ensure(h: number) { if (this.y + h <= this.bottom()) return; this.doc.addPage(); this.paintBg(); this.y = PAGE.margin; }
  private fontB(n: number) { this.doc.font(FONTS.bold).fontSize(n); }
  private fontR(n: number) { this.doc.font(FONTS.regular).fontSize(n); }
  private boxHeader(x: number, y: number, w: number, t: string, fill: string) {
    this.doc.rect(x, y, w, PAGE.headerH).fill(fill);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, PAGE.headerH).stroke();
    this.fontB(8.4); this.doc.fillColor(COLORS.text).text(t, x + 4, y + 3, { width: w - 8, lineBreak: false, ellipsis: true });
  }
  private shell(x: number, y: number, w: number, h: number, t: string, fill: string) {
    this.boxHeader(x, y, w, t, fill);
    this.doc.rect(x, y + PAGE.headerH, w, h - PAGE.headerH).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
  }
  private kvBox(x: number, y: number, w: number, title: string, rows: { label: string; value: string }[]) {
    const rowH = 14; const h = PAGE.headerH + Math.max(1, rows.length) * rowH; const split = x + w * 0.45;
    this.shell(x, y, w, h, title, COLORS.headerDefault);
    let cy = y + PAGE.headerH;
    rows.forEach((r, i) => {
      if (i > 0) this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.doc.moveTo(split, cy).lineTo(split, cy + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(7.2); this.doc.fillColor(COLORS.text).text(r.label, x + 4, cy + 3, { width: split - x - 8, lineBreak: false, ellipsis: true });
      this.fontR(7.1); this.doc.fillColor(COLORS.text).text(r.value, split + 4, cy + 3, { width: x + w - split - 8, lineBreak: false, ellipsis: true });
      cy += rowH;
    });
    return h;
  }
  private baseHeaderBox(
    x: number,
    y: number,
    w: number,
    title: string,
    rows: { label: string; value: string }[],
    definingLabel: string,
    definingLeftValue: string,
    definingCells: { skillCur: string; skillBonus: string; skillRaceBonus: string; basis: string },
    fixedHeight?: number,
  ) {
    const rowH = 12;
    const totalRows = rows.length + 2;
    const h = Math.max(PAGE.headerH + totalRows * rowH, fixedHeight ?? 0);
    this.shell(x, y, w, h, title, COLORS.headerDefault);
    let cy = y + PAGE.headerH;

    rows.forEach((r, i) => {
      if (i > 0) this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(7.0);
      this.doc.fillColor(COLORS.text).text(r.label, x + 4, cy + 2, { width: w * 0.45 - 8, lineBreak: false, ellipsis: true });
      this.fontR(7.0);
      this.doc.fillColor(COLORS.text).text(r.value, x + w * 0.42, cy + 2, { width: w * 0.58 - 6, lineBreak: false, ellipsis: true });
      cy += rowH;
    });

    this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(7.0);
      this.doc.fillColor(COLORS.text).text(definingLabel, x + 4, cy + 2, { width: w - 8, lineBreak: false, ellipsis: true });
      cy += rowH;

    // No horizontal line between "Defining skill" label row and its value row.
    this.fontR(6.85);
    const cells = [
      { text: definingCells.skillCur, bold: false },
      { text: definingCells.skillBonus, bold: false },
      { text: definingCells.skillRaceBonus, bold: true },
      { text: definingCells.basis, bold: false },
    ];
    const gap = 2;
    const measuredWidths = cells.map((cell) => {
      if (!cell.text) return 0;
      if (cell.bold) this.fontB(6.2); else this.fontR(6.2);
      return Math.ceil(this.doc.widthOfString(cell.text)) + 2;
    });
    const widths = [
      Math.max(0, measuredWidths[0] ?? 0),
      Math.max(0, measuredWidths[1] ?? 0),
      Math.max(0, measuredWidths[2] ?? 0),
      Math.max(0, measuredWidths[3] ?? 0),
    ];
    const visibleCells = cells.reduce((acc, c) => acc + (c.text ? 1 : 0), 0);
    const rightW = widths.reduce((a, b) => a + b, 0) + Math.max(0, visibleCells - 1) * gap;
    const leftPad = 4;
    const rightPad = 4;
    const leftW = Math.max(12, w - leftPad - rightPad - rightW - 4);
    this.fontR(6.85);
    this.doc.fillColor(COLORS.text).text(definingLeftValue, x + leftPad, cy + 2, {
      width: leftW,
      height: rowH - 2,
      lineBreak: false,
      ellipsis: true,
    });
    let rx = x + w - rightPad - rightW;
    for (let i = 0; i < cells.length; i += 1) {
      const cell = cells[i]!;
      const cw = widths[i]!;
      if (!cw) continue;
      if (cell.bold) this.fontB(6.2); else this.fontR(6.2);
      this.doc.fillColor(COLORS.text).text(cell.text, rx, cy + 2, {
        width: cw,
        align: 'right',
        height: rowH - 2,
        lineBreak: false,
        ellipsis: true,
      });
      rx += cw;
      if (i < cells.length - 1) {
        let hasNextVisible = false;
        for (let j = i + 1; j < cells.length; j += 1) {
          if (widths[j] && cells[j]!.text) {
            hasNextVisible = true;
            break;
          }
        }
        if (hasNextVisible) rx += gap;
      }
    }
    return h;
  }
  private topParamsCombinedBox(
    x: number,
    y: number,
    w: number,
    mainTitle: string,
    mainRows: Row[],
    extraTitle: string,
    extraRows: Row[],
    fixedHeight?: number,
  ) {
    const rowH = 12;
    const subHeaderH = 13;
    const pairX1 = x + 4;
    const pairV1 = x + w * 0.32;
    const pairX2 = x + w * 0.53;
    const pairV2 = x + w - 4;
    const h = Math.max(PAGE.headerH + 4 * rowH + subHeaderH + 4 * rowH, fixedHeight ?? 0);
    this.shell(x, y, w, h, mainTitle, COLORS.headerDefault);
    let cy = y + PAGE.headerH;

    const drawRichValueRight = (parts: Array<{ text: string; bold?: boolean }>, x0: number, y0: number, width: number) => {
      const visible = parts.filter((p) => p.text);
      if (!visible.length) return;
      const widths = visible.map((p) => {
        if (p.bold) this.fontB(6.9); else this.fontR(6.9);
        return Math.ceil(this.doc.widthOfString(p.text));
      });
      let rx = x0 + width - widths.reduce((a, b) => a + b, 0);
      for (let i = 0; i < visible.length; i += 1) {
        const p = visible[i]!;
        const pw = widths[i]!;
        if (p.bold) this.fontB(6.9); else this.fontR(6.9);
        this.doc.fillColor(COLORS.text).text(p.text, rx, y0, { width: pw, lineBreak: false, ellipsis: true });
        rx += pw;
      }
    };

    const drawPairRow = (left?: Row, right?: Row) => {
      if (cy > y + PAGE.headerH) this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const lLabel = left?.cells[0] ?? '';
      const lBonus = left?.cells[2] && left.cells[2] !== '—' ? String(left.cells[2]).replace(/\s+/g, '') : '';
      const lRace = left?.cells[3] && left.cells[3] !== '—' ? String(left.cells[3]).replace(/\s+/g, '') : '';
      const lVal = left?.cells[1] ? `${left.cells[1]}${lBonus}${lRace}` : '';
      const rLabel = right?.cells[0] ?? '';
      const rBonus = right?.cells[2] && right.cells[2] !== '—' ? String(right.cells[2]).replace(/\s+/g, '') : '';
      const rRace = right?.cells[3] && right.cells[3] !== '—' ? String(right.cells[3]).replace(/\s+/g, '') : '';
      const rVal = right?.cells[1] ? `${right.cells[1]}${rBonus}${rRace}` : '';
      this.fontB(6.9);
      this.doc.fillColor(COLORS.text).text(lLabel, pairX1, cy + 2, { width: pairV1 - pairX1 - 2, lineBreak: false, ellipsis: true });
      if (left?.cells?.length && left.cells[3] !== undefined) {
        drawRichValueRight([
          { text: String(left.cells[1] ?? '') },
          { text: lBonus },
          { text: lRace, bold: true },
        ], pairV1, cy + 2, pairX2 - pairV1 - 6);
      } else {
        this.fontR(6.9);
        this.doc.fillColor(COLORS.text).text(lVal, pairV1, cy + 2, { width: pairX2 - pairV1 - 6, align: 'right', lineBreak: false, ellipsis: true });
      }
      this.fontB(6.9);
      this.doc.fillColor(COLORS.text).text(rLabel, pairX2, cy + 2, { width: pairV2 - pairX2 - 18, lineBreak: false, ellipsis: true });
      if (right?.cells?.length && right.cells[3] !== undefined) {
        drawRichValueRight([
          { text: String(right.cells[1] ?? '') },
          { text: rBonus },
          { text: rRace, bold: true },
        ], pairX2 + 14, cy + 2, pairV2 - (pairX2 + 14));
      } else {
        this.fontR(6.9);
        this.doc.fillColor(COLORS.text).text(rVal, pairX2 + 14, cy + 2, { width: pairV2 - (pairX2 + 14), align: 'right', lineBreak: false, ellipsis: true });
      }
      cy += rowH;
    };

    for (let i = 0; i < 4; i += 1) {
      drawPairRow(mainRows[i * 2], mainRows[i * 2 + 1]);
    }

    this.doc.rect(x, cy, w, subHeaderH).fill(COLORS.headerDefault);
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(x, cy, w, subHeaderH).stroke();
    this.fontB(7.2);
    this.doc.fillColor(COLORS.text).text(extraTitle, x + 4, cy + 3, { width: w - 8, lineBreak: false, ellipsis: true });
    cy += subHeaderH;

    const extraPairs: Array<[Row | undefined, Row | undefined]> = [
      [extraRows[0], extraRows[1]],
      [extraRows[2], extraRows[3]],
      [extraRows[4], extraRows[5]],
      [extraRows[6], undefined],
    ];
    for (const [l, r] of extraPairs) drawPairRow(l, r);
    return h;
  }
  private topConsumablesBox(x: number, y: number, w: number, title: string, table: Table, fixedHeight?: number) {
    const rowH = 13;
    const headH = 14;
    const rows = table.rows.slice(0, 5);
    const h = Math.max(PAGE.headerH + headH + 5 * rowH, fixedHeight ?? 0);
    this.shell(x, y, w, h, title, COLORS.headerDefault);
    const ty = y + PAGE.headerH;
    this.doc.rect(x, ty, w, headH).fill(COLORS.headerDefault);
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(x, ty, w, headH).stroke();
    const header0 = (table.columns[0] ?? '').replace(/^Название$/i, 'ПАРАМЕТР');
    const valuesCol1 = rows.map((r) => r?.cells[1] ?? '');
    const valuesCol0 = rows.map((r) => r?.cells[0] ?? '');
    this.fontB(6.8);
    const nameW = Math.min(
      Math.max(
        52,
        Math.ceil(this.doc.widthOfString(header0)) + 8,
        ...valuesCol0.map((v) => Math.ceil(this.doc.widthOfString(String(v))) + 8),
      ),
      Math.floor(w * 0.68),
    );
    const maxW = Math.min(
      Math.max(
        34,
        Math.ceil(this.doc.widthOfString(table.columns[1] ?? '')) + 8,
        ...valuesCol1.map((v) => Math.ceil(this.doc.widthOfString(String(v))) + 8),
      ),
      Math.floor(w * 0.24),
    );
    const c1 = x + nameW;
    const c2 = x + nameW + maxW;
    this.fontB(6.8);
    this.doc.fillColor(COLORS.text).text(header0, x + 3, ty + 2, { width: c1 - x - 6, lineBreak: false, ellipsis: true });
    this.doc.fillColor(COLORS.text).text(table.columns[1] ?? '', c1 + 2, ty + 2, { width: c2 - c1 - 4, align: 'center', lineBreak: false, ellipsis: true });
    this.doc.fillColor(COLORS.text).text(table.columns[2] ?? '', c2 + 2, ty + 2, { width: x + w - c2 - 4, align: 'center', lineBreak: false, ellipsis: true });
    let ry = ty + headH;
    for (let i = 0; i < 5; i += 1) {
      this.doc.moveTo(x, ry).lineTo(x + w, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const row = rows[i];
      this.fontR(6.4);
      this.doc.fillColor(COLORS.text).text(row?.cells[0] ?? '', x + 3, ry + 2, { width: c1 - x - 6, height: rowH - 2 });
      this.doc.fillColor(COLORS.text).text(row?.cells[1] ?? '', c1 + 2, ry + 2, { width: c2 - c1 - 4, align: 'center', lineBreak: false, ellipsis: true });
      this.doc.fillColor(COLORS.text).text((row?.cells[2] ?? '').trim() === '0.0' ? '' : (row?.cells[2] ?? ''), c2 + 2, ry + 2, { width: x + w - c2 - 4, align: 'center', lineBreak: false, ellipsis: true });
      ry += rowH;
    }
    return h;
  }
  private drawValueCellsRow(
    x: number,
    y: number,
    w: number,
    cells: ValueCells,
    opts?: { fontSize?: number; fixedWidths?: [number, number, number, number] },
  ): number {
    const fontSize = opts?.fontSize ?? 6.2;
    const gap = 2;
    const items = [
      { text: cells.cur, bold: false },
      { text: cells.bonus, bold: false },
      { text: cells.raceBonus, bold: true },
      { text: cells.final, bold: false },
    ];
    const measuredWidths = items.map((it) => {
      if (!it.text) return 0;
      if (it.bold) this.fontB(fontSize); else this.fontR(fontSize);
      return Math.ceil(this.doc.widthOfString(it.text)) + 2;
    });
    const hasFixedWidths = Boolean(opts?.fixedWidths);
    const widths = opts?.fixedWidths ? [...opts.fixedWidths] : measuredWidths;
    const visibleCount = opts?.fixedWidths
      ? items.length
      : items.reduce((acc, it, idx) => acc + (it.text && widths[idx]! > 0 ? 1 : 0), 0);
    const rightW = widths.reduce((a, b) => a + b, 0) + Math.max(0, visibleCount - 1) * gap;
    let rx = x + w - 4 - rightW;
    for (let i = 0; i < items.length; i += 1) {
      const it = items[i]!;
      const width = widths[i]!;
      if (width > 0 && it.text) {
        if (it.bold) this.fontB(fontSize); else this.fontR(fontSize);
        this.doc.fillColor(COLORS.text).text(it.text, rx, y, {
          width,
          align: 'right',
          lineBreak: false,
          ellipsis: true,
        });
      }
      rx += width;
      if (hasFixedWidths) {
        if (i < items.length - 1) rx += gap;
      } else {
        let hasNextVisible = false;
        for (let j = i + 1; j < items.length; j += 1) {
          if (items[j]!.text && widths[j]! > 0) {
            hasNextVisible = true;
            break;
          }
        }
        if (hasNextVisible) rx += gap;
      }
    }
    return rightW;
  }
  private drawSkillSidebar(x: number, y: number, w: number, h: number, groups: SkillSidebarGroup[]) {
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    let headerH = 14;
    let rowFont = 6.6;
    let valueFont = 6.0;
    let headerValueFont = 6.1;
    let minRowH = 12;
    const sidebarColWidths: [number, number, number, number] = [0, 0, 0, 0];
    const measureSidebarCells = (cells: ValueCells, fontSize: number) => {
      const vals = [
        { t: cells.cur, bold: false },
        { t: cells.bonus, bold: false },
        { t: cells.raceBonus, bold: true },
        { t: cells.final, bold: false },
      ] as const;
      vals.forEach((v, i) => {
        if (!v.t) return;
        if (v.bold) this.fontB(fontSize); else this.fontR(fontSize);
        const width = Math.ceil(this.doc.widthOfString(v.t)) + 2;
        if (width > sidebarColWidths[i]!) sidebarColWidths[i] = width;
      });
    };
    const recalcWidths = () => {
      sidebarColWidths[0] = 0; sidebarColWidths[1] = 0; sidebarColWidths[2] = 0; sidebarColWidths[3] = 0;
      for (const group of groups) {
        measureSidebarCells(group.statCells, headerValueFont);
        for (const row of group.rows) measureSidebarCells(row.cells, valueFont);
      }
      sidebarColWidths.forEach((v, i) => { if (v <= 0) sidebarColWidths[i] = 7; });
    };
    const measureTotalHeight = () => {
      recalcWidths();
      const sidebarRightW = sidebarColWidths.reduce((a, b) => a + b, 0) + 2 * 3;
      let total = 0;
      for (const group of groups) {
        total += headerH;
        for (const row of group.rows) {
          this.fontR(rowFont);
          const leftW = Math.max(18, w - sidebarRightW - 12);
          const textH = Math.ceil(this.doc.heightOfString(row.name, { width: leftW }));
          total += Math.max(minRowH, textH + 2);
        }
      }
      return { total, sidebarRightW };
    };
    let measured = measureTotalHeight();
    if (measured.total > h) {
      headerH = 13;
      rowFont = 6.1;
      valueFont = 5.8;
      headerValueFont = 5.9;
      minRowH = 10;
      measured = measureTotalHeight();
    }
    if (measured.total > h) {
      headerH = 12;
      rowFont = 5.8;
      valueFont = 5.5;
      headerValueFont = 5.6;
      minRowH = 9;
      measured = measureTotalHeight();
    }
    const totalRowCount = groups.reduce((acc, g) => acc + g.rows.length, 0);
    const spare = Math.max(0, h - measured.total);
    const rowExtraPad = totalRowCount > 0 ? Math.min(2, Math.floor(spare / totalRowCount)) : 0;
    const sidebarRightW = measured.sidebarRightW;
    let cy = y;
    for (const group of groups) {
      let groupHeight = headerH;
      const measuredRowHeights: number[] = [];
      for (const row of group.rows) {
        this.fontR(rowFont);
        const leftW = Math.max(20, w - sidebarRightW - 12);
        const textH = Math.ceil(this.doc.heightOfString(row.name, { width: leftW }));
        const rowH = Math.max(minRowH, textH + 2 + rowExtraPad);
        measuredRowHeights.push(rowH);
        groupHeight += rowH;
      }
      if (cy + groupHeight > y + h) break;
      this.doc.rect(x, cy, w, headerH).fill(COLORS.headerDefault);
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(x, cy, w, headerH).stroke();
      this.fontB(headerH <= 12 ? 6.7 : 7.1);
      this.doc.fillColor(COLORS.text).text(group.title, x + 4, cy + 3, {
        width: Math.max(18, w - sidebarRightW - 10),
        lineBreak: false,
        ellipsis: true,
      });
      const statExpr = formatStatHeaderExpression(group.statCells);
      this.fontB(headerValueFont);
      this.doc.fillColor(COLORS.text).text(statExpr, x + 4, cy + 3, {
        width: w - 8,
        align: 'right',
        lineBreak: false,
        ellipsis: true,
      });
      cy += headerH;

      for (let i = 0; i < group.rows.length; i += 1) {
        const row = group.rows[i]!;
        const rowH = measuredRowHeights[i] ?? 12;
        this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor('#d7dbe0').lineWidth(0.2).stroke();
        this.drawValueCellsRow(x, cy + 1, w, row.cells, { fontSize: valueFont, fixedWidths: sidebarColWidths });
        const leftW = Math.max(20, w - sidebarRightW - 12);
        this.fontR(rowFont);
        this.doc.fillColor(COLORS.text).text(row.name, x + 4, cy + 2, {
          width: leftW,
          height: rowH - 3,
        });
        cy += rowH;
      }
    }
  }
  private drawProfessionalBranches(x: number, y: number, w: number, branches: ProfBranch[], title: string): number {
    const titleH = PAGE.headerH;
    const gap = PAGE.gap;
    const colW = (w - gap * 2) / 3;
    this.fontB(8.4);
    this.doc.fillColor(COLORS.text).text(title, x + 4, y + 3, { width: w - 8, lineBreak: false, ellipsis: true });
    const by = y + titleH;
    const branchLayouts = branches.slice(0, 3).map((b, idx) => {
      const bx = x + idx * (colW + gap);
      const fill = b.color === 'blue' ? COLORS.profBlue : b.color === 'mint' ? COLORS.profMint : COLORS.profRose;
      const rowHeights: number[] = [];
      const split = bx + colW * 0.8;
      this.fontR(6.5);
      for (let i = 0; i < 3; i += 1) {
        const row = b.rows[i];
        const left = row ? `${row.name}${row.paramAbbr ? ` (${row.paramAbbr})` : ''}` : '';
        const textH = left ? Math.ceil(this.doc.heightOfString(left, { width: split - bx - 6 })) : 0;
        rowHeights.push(Math.max(13, textH + 3));
      }
      const bodyH = rowHeights.reduce((a, v) => a + v, 0);
      return { b, idx, bx, fill, split, rowHeights, bodyH };
    });
    const maxBodyH = Math.max(0, ...branchLayouts.map((l) => l.bodyH));
    let maxBranchH = PAGE.headerH + maxBodyH;
    branchLayouts.forEach((layout) => {
      const extra = Math.max(0, maxBodyH - layout.bodyH);
      if (extra > 0) {
        const baseAdd = Math.floor(extra / layout.rowHeights.length);
        let rem = extra % layout.rowHeights.length;
        for (let i = 0; i < layout.rowHeights.length; i += 1) {
          layout.rowHeights[i]! += baseAdd + (rem > 0 ? 1 : 0);
          if (rem > 0) rem -= 1;
        }
      }
      const { b, bx, fill, split, rowHeights } = layout;
      const bodyH = rowHeights.reduce((a, v) => a + v, 0);
      const boxH = PAGE.headerH + bodyH;
      this.doc.rect(bx, by, colW, boxH).fill('#ffffff');
      this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(bx, by, colW, boxH).stroke();
      this.doc.rect(bx, by, colW, PAGE.headerH).fill(fill);
      this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(bx, by, colW, PAGE.headerH).stroke();
      this.fontB(8.4);
      this.doc.fillColor(COLORS.text).text(b.title.toUpperCase(), bx + 4, by + 3, { width: colW - 8, lineBreak: false, ellipsis: true });
      let ry = by + PAGE.headerH;
      for (let i = 0; i < 3; i += 1) {
        const rowH = rowHeights[i] ?? 13;
        this.doc.moveTo(bx, ry).lineTo(bx + colW, ry).strokeColor(COLORS.line).lineWidth(0.2).stroke();
        this.doc.rect(bx, ry, split - bx, rowH).fill(fill);
        this.doc.lineWidth(0.2).strokeColor(COLORS.line).rect(bx, ry, split - bx, rowH).stroke();
        this.doc.lineWidth(0.2).strokeColor(COLORS.line).rect(split, ry, bx + colW - split, rowH).stroke();
        const row = b.rows[i];
        const left = row ? `${row.name}${row.paramAbbr ? ` (${row.paramAbbr})` : ''}` : '';
        this.fontR(6.5);
        this.doc.fillColor(COLORS.text).text(left, bx + 3, ry + 1, {
          width: split - bx - 6,
          height: rowH - 2,
        });
        ry += rowH;
      }
    });
    return titleH + maxBranchH;
  }
  private drawPerksCompact(x: number, y: number, w: number, table: Table): number {
    const tableLang: 'ru' | 'en' = /[А-Яа-яЁё]/.test(`${table.title} ${table.columns.join(' ')}`) ? 'ru' : 'en';
    const rows = table.rows.slice(0, 6).map((r) => ({
      name: stripHtmlTags((r.cells[0] ?? '').trim()),
      effect: stripHtmlTags((r.cells[1] ?? '').trim()),
    }));
    const headerH = PAGE.headerH;
    const nameWMeasured = rows.reduce((m, r) => {
      this.fontB(7.0);
      return Math.max(m, Math.ceil(this.doc.widthOfString(r.name || '—')) + 8);
    }, 72);
    const nameW = Math.min(Math.max(72, nameWMeasured), Math.floor(w * 0.26));
    const rowHeights = rows.map((r) => {
      this.fontR(6.2);
      return Math.max(12, Math.ceil(this.doc.heightOfString(r.effect || '—', { width: Math.max(20, w - nameW - 8) })) + 1);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.headerPerks);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    this.doc.moveTo(x + nameW, y).lineTo(x + nameW, y + h).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    this.fontB(8.4);
    this.doc.fillColor(COLORS.text).text((table.columns[0] ?? (tableLang === 'ru' ? 'ПЕРК' : 'PERK')).toUpperCase(), x + 4, y + 3, { width: nameW - 8, lineBreak: false, ellipsis: true });
    this.doc.fillColor(COLORS.text).text((table.columns[1] ?? (tableLang === 'ru' ? 'ЭФФЕКТ' : 'EFFECT')).toUpperCase(), x + nameW + 2, y + 3, { width: w - nameW - 4, align: 'center', lineBreak: false, ellipsis: true });
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(6.8);
      this.doc.fillColor(COLORS.text).text(row.name || '—', x + 3, cy + 1, { width: nameW - 6, height: rowH - 2 });
      this.fontR(6.1);
      this.doc.fillColor(COLORS.text).text(row.effect || '—', x + nameW + 3, cy + 1, { width: w - nameW - 6, height: rowH - 2 });
      cy += rowH;
    }
    this.doc.moveTo(x, y + h).lineTo(x + w, y + h).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }
  private drawWeaponsCompact(x: number, y: number, w: number, table: Table): number {
    const headerH = PAGE.headerH;
    const srcRows = table.rows.map((r) => {
      const rawName = (r.cells[1] ?? '').trim();
      const parts = rawName.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
      const name = parts[0] ?? '—';
      const effectFromName = parts.slice(1).join(' ');
      const effect = normalizeInlineEffects((r.cells[10] ?? effectFromName ?? '').trim());
      return {
        qty: (r.cells[0] ?? '').trim(),
        name: stripHtmlTags(name),
        effect,
        dmg: (r.cells[2] ?? '').trim(),
        type: (r.cells[3] ?? '').trim(),
        rel: (r.cells[4] ?? '').trim(),
        hands: (r.cells[5] ?? '').trim(),
        conceal: (r.cells[6] ?? '').trim(),
        enh: (r.cells[7] ?? '').trim(),
        wt: (r.cells[8] ?? '').trim(),
        price: (r.cells[9] ?? '').trim(),
      };
    });
    const rows = [...srcRows, ...new Array(3).fill(null).map(() => ({
      qty: '', name: '', effect: '', dmg: '', type: '', rel: '', hands: '', conceal: '', enh: '', wt: '', price: '',
    }))];
    const headers = (table.columns.length >= 11
      ? table.columns
      : [' ', '#', 'ОРУЖИЕ', 'УРОН', 'ТИП', 'Н', 'ХВАТ', 'СКР', 'УС', 'ВЕС', 'ЦЕНА']).map((h, i) => (i === 0 ? ' ' : String(h || '').toUpperCase()));
    const checkW = 14;
    const fitDefs: Array<{ key: keyof (typeof rows)[number]; header: string; min: number }> = [
      { key: 'qty', header: headers[1] ?? '#', min: 12 },
      { key: 'dmg', header: headers[3] ?? 'УРОН', min: 20 },
      { key: 'type', header: headers[4] ?? 'ТИП', min: 16 },
      { key: 'rel', header: headers[5] ?? 'Н', min: 14 },
      { key: 'hands', header: headers[6] ?? 'ХВАТ', min: 20 },
      { key: 'conceal', header: headers[7] ?? 'СКР', min: 18 },
      { key: 'enh', header: headers[8] ?? 'УС', min: 16 },
      { key: 'wt', header: headers[9] ?? 'ВЕС', min: 18 },
      { key: 'price', header: headers[10] ?? 'ЦЕНА', min: 20 },
    ];
    const fitWidths = fitDefs.map((d) => {
      this.fontB(6.5);
      let mw = Math.max(d.min, Math.ceil(this.doc.widthOfString(d.header)) + 6);
      this.fontR(6.4);
      for (const row of rows) mw = Math.max(mw, Math.ceil(this.doc.widthOfString(String(row[d.key] || ''))) + 6);
      return mw;
    });
    const nonNameW = checkW + fitWidths.reduce((a, v) => a + v, 0);
    const nameW = Math.max(110, w - nonNameW);
    const rowHeights = rows.map((row) => {
      if (!row.name && !row.effect) return 12;
      this.fontR(6.4);
      const nameH = Math.ceil(this.doc.heightOfString(row.name || '—', { width: nameW - 6 }));
      let effectH = 0;
      if (row.effect) {
        this.doc.font(FONTS.regular).fontSize(5.8);
        effectH = Math.ceil(this.doc.heightOfString(row.effect, { width: nameW - 6 }));
      }
      return Math.max(12, nameH + (row.effect ? effectH + 1 : 0) + 1);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.headerWeapons);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    const cols = [checkW, fitWidths[0]!, nameW, ...fitWidths.slice(1)];
    const headerFontSize = 6.5;
    let cx = x;
    for (let i = 0; i < cols.length; i += 1) {
      const cw = cols[i]!;
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, y, cw, h).stroke();
      const headerText = i === 0 ? ' ' : (headers[i] ?? '');
      this.fontB(headerFontSize);
      const headerTextH = Math.ceil(this.doc.heightOfString(headerText, { width: cw - 4, lineBreak: false }));
      const headerY = y + Math.max(1, Math.floor((headerH - headerTextH) / 2));
      this.doc.fillColor(COLORS.text).text(headerText, cx + 2, headerY, {
        width: cw - 4,
        align: i >= 3 || i === 1 ? 'center' : (i === 2 ? 'left' : 'center'),
        lineBreak: false,
        ellipsis: true,
      });
      cx += cw;
    }
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const vals = [' ', row.qty, row.name, row.dmg, row.type, row.rel, row.hands, row.conceal, row.enh, row.wt, row.price];
      let rx = x;
      for (let c = 0; c < cols.length; c += 1) {
        const cw = cols[c]!;
        if (c === 2) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 3, cy + 1, { width: cw - 6, height: rowH - 2 });
          if (row.effect) {
            const nameHeight = Math.ceil(this.doc.heightOfString(row.name || '—', { width: cw - 6 }));
            this.doc.font(FONTS.regular).fontSize(5.8).fillColor('#6a6a6a').text(row.effect, rx + 3, cy + 1 + nameHeight, { width: cw - 6, height: rowH - 2, oblique: true });
          }
        } else if (c !== 0) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 2, cy + 1, {
            width: cw - 4,
            align: c === 1 || c >= 3 ? 'center' : 'right',
            lineBreak: false,
            ellipsis: true,
          });
        }
        rx += cw;
      }
      cy += rowH;
    }
    return h;
  }
  private drawArmorDoll(x: number, y: number, w: number): number {
    // `doll.png` source is 218x400. Use aspect ratio to avoid oversized invisible box.
    const targetH = Math.round((Math.max(8, w - 4) * 400) / 218) + 4;
    const pad = 2;
    const boxH = targetH;

    const candidates = [
      '/var/task/assets/doll.png',
      path.join(process.cwd(), 'src', 'pdf', 'assets', 'doll.png'),
      path.join(process.cwd(), 'cloud', 'api', 'src', 'pdf', 'assets', 'doll.png'),
      path.join(process.cwd(), 'apps', 'api', 'src', 'pdf', 'assets', 'doll.png'),
    ];
    const dollPath = candidates.find((p) => fs.existsSync(p));
    if (!dollPath) {
      this.fontR(6.5);
      this.doc.fillColor(COLORS.muted).text('doll.png', x + 2, y + Math.max(2, Math.floor(boxH / 2) - 4), { width: w - 4, align: 'center', lineBreak: false, ellipsis: true });
      return boxH;
    }

    try {
      this.doc.image(dollPath, x + pad, y + pad, {
        fit: [w - pad * 2, boxH - pad * 2],
        align: 'center',
      });
    } catch {
      this.fontR(6.5);
      this.doc.fillColor(COLORS.muted).text('doll.png', x + 2, y + Math.max(2, Math.floor(boxH / 2) - 4), { width: w - 4, align: 'center', lineBreak: false, ellipsis: true });
    }
    return boxH;
  }
  private drawArmorCompact(x: number, y: number, w: number, table: Table): number {
    const headerH = PAGE.headerH;
    const srcRows = table.rows.map((r) => ({
      qty: (r.cells[0] ?? '').trim(),
      name: stripHtmlTags((r.cells[1] ?? '').trim()),
      sp: (r.cells[2] ?? '').trim(),
      enc: (r.cells[3] ?? '').trim(),
      enh: (r.cells[4] ?? '').trim(),
      wt: (r.cells[5] ?? '').trim(),
      price: (r.cells[6] ?? '').trim(),
      effect: normalizeInlineEffects((r.cells[7] ?? '').trim()),
    }));
    const totalRows = Math.max(srcRows.length + 3, 6);
    const rows = [...srcRows, ...new Array(Math.max(0, totalRows - srcRows.length)).fill(null).map(() => ({ qty: '', name: '', sp: '', enc: '', enh: '', wt: '', price: '', effect: '' }))];
    const headers = (table.columns.length >= 8 ? table.columns : [' ', '#', 'БРОНЯ', 'ПБ/Н', 'СД', 'УБ', 'ВЕС', 'ЦЕНА']).map((h, i) => (i === 0 ? ' ' : String(h || '').toUpperCase()));
    const checkW = 14;
    const fitDefs: Array<{ key: keyof (typeof rows)[number]; header: string; min: number }> = [
      { key: 'qty', header: headers[1] ?? '#', min: 12 },
      { key: 'sp', header: headers[3] ?? 'SP', min: 22 },
      { key: 'enc', header: headers[4] ?? 'ENC', min: 18 },
      { key: 'enh', header: headers[5] ?? 'ENH', min: 18 },
      { key: 'wt', header: headers[6] ?? 'WT', min: 20 },
      { key: 'price', header: headers[7] ?? 'PRICE', min: 22 },
    ];
    const fitWidths = fitDefs.map((d) => {
      this.fontB(6.5);
      let mw = Math.max(d.min, Math.ceil(this.doc.widthOfString(d.header)) + 6);
      this.fontR(6.4);
      for (const row of rows) mw = Math.max(mw, Math.ceil(this.doc.widthOfString(String(row[d.key] || ''))) + 6);
      return mw;
    });
    const nonNameW = checkW + fitWidths.reduce((a, v) => a + v, 0);
    const nameW = Math.max(100, w - nonNameW);
    const rowHeights = rows.map((row) => {
      if (!row.name && !row.effect) return 12;
      this.fontR(6.4);
      const nameH = Math.ceil(this.doc.heightOfString(row.name || '—', { width: nameW - 6 }));
      let effectH = 0;
      if (row.effect) {
        this.doc.font(FONTS.regular).fontSize(5.8);
        effectH = Math.ceil(this.doc.heightOfString(row.effect, { width: nameW - 6 }));
      }
      return Math.max(12, nameH + (row.effect ? effectH + 1 : 0) + 1);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.headerArmors);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    const cols = [checkW, fitWidths[0]!, nameW, ...fitWidths.slice(1)];
    const headerFontSize = 6.5;
    let cx = x;
    for (let i = 0; i < cols.length; i += 1) {
      const cw = cols[i]!;
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, y, cw, h).stroke();
      const headerText = i === 0 ? ' ' : (headers[i] ?? '');
      this.fontB(headerFontSize);
      const headerTextH = Math.ceil(this.doc.heightOfString(headerText, { width: cw - 4, lineBreak: false }));
      const headerY = y + Math.max(1, Math.floor((headerH - headerTextH) / 2));
      this.doc.fillColor(COLORS.text).text(headerText, cx + 2, headerY, {
        width: cw - 4,
        align: i >= 3 || i === 1 ? 'center' : (i === 2 ? 'left' : 'center'),
        lineBreak: false,
        ellipsis: true,
      });
      cx += cw;
    }
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const vals = [' ', row.qty, row.name, row.sp, row.enc, row.enh, row.wt, row.price];
      let rx = x;
      for (let c = 0; c < cols.length; c += 1) {
        const cw = cols[c]!;
        if (c === 2) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 3, cy + 1, { width: cw - 6, height: rowH - 2 });
          if (row.effect) {
            const nameHeight = Math.ceil(this.doc.heightOfString(row.name || '—', { width: cw - 6 }));
            this.doc.font(FONTS.regular).fontSize(5.8).fillColor('#6a6a6a').text(row.effect, rx + 3, cy + 1 + nameHeight, { width: cw - 6, height: rowH - 2, oblique: true });
          }
        } else if (c !== 0) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 2, cy + 1, {
            width: cw - 4,
            align: c === 1 || c >= 3 ? 'center' : 'right',
            lineBreak: false,
            ellipsis: true,
          });
        }
        rx += cw;
      }
      cy += rowH;
    }
    return h;
  }
  private drawAlchemyCompact(x: number, y: number, w: number, table: Table): number {
    const headerH = PAGE.headerH;
    const srcRows = table.rows.map((r) => ({
      qty: (r.cells[0] ?? '').trim(),
      name: stripHtmlTags((r.cells[1] ?? '').trim()),
      tox: (r.cells[2] ?? '').trim(),
      time: (r.cells[3] ?? '').trim(),
      effect: normalizeInlineEffects((r.cells[4] ?? '').trim()),
      wt: (r.cells[5] ?? '').trim(),
      price: (r.cells[6] ?? '').trim(),
    }));
    const totalRows = Math.max(srcRows.length + 3, 3);
    const rows = [...srcRows, ...new Array(Math.max(0, totalRows - srcRows.length)).fill(null).map(() => ({ qty: '', name: '', tox: '', time: '', effect: '', wt: '', price: '' }))];
    const tableLang: 'ru' | 'en' = /[А-Яа-яЁё]/.test(`${table.title} ${table.columns.join(' ')}`) ? 'ru' : 'en';
    const headers = (table.columns.length >= 7 ? table.columns : ['#', 'АЛХИМИЯ', 'ТОКС', 'ВРЕМЯ', 'ЭФФЕКТ', 'ВЕС', 'ЦЕНА'])
      .map((h) => String(h || '').toUpperCase());
    headers[1] = tableLang === 'ru' ? 'ХИМИКАТ' : 'CHEMICAL';
    const fitDefs: Array<{ key: keyof (typeof rows)[number]; header: string; min: number }> = [
      { key: 'qty', header: headers[0] ?? '#', min: 14 },
      { key: 'name', header: headers[1] ?? 'АЛХИМИЯ', min: 56 },
      { key: 'tox', header: headers[2] ?? 'ТОКС', min: 22 },
      { key: 'time', header: headers[3] ?? 'ВРЕМЯ', min: 30 },
      { key: 'wt', header: headers[5] ?? 'ВЕС', min: 20 },
      { key: 'price', header: headers[6] ?? 'ЦЕНА', min: 22 },
    ];
    const fitWidths = fitDefs.map((d) => {
      this.fontB(6.5);
      let mw = Math.max(d.min, Math.ceil(this.doc.widthOfString(d.header)) + 6);
      this.fontR(6.2);
      for (const row of rows) mw = Math.max(mw, Math.ceil(this.doc.widthOfString(String(row[d.key] || ''))) + 6);
      return mw;
    });
    const nonFlex = fitWidths.reduce((a, v) => a + v, 0);
    const effectW = Math.max(100, w - nonFlex);
    const rowHeights = rows.map((row) => {
      if (!row.effect) return 12;
      this.fontR(6.0);
      return Math.max(12, Math.ceil(this.doc.heightOfString(row.effect, { width: effectW - 6 })) + 1);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.headerPotions);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    const cols = [fitWidths[0]!, fitWidths[1]!, fitWidths[2]!, fitWidths[3]!, effectW, fitWidths[4]!, fitWidths[5]!];
    const headerFontSize = 6.5;
    let cx = x;
    for (let i = 0; i < cols.length; i += 1) {
      const cw = cols[i]!;
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, y, cw, h).stroke();
      const headerText = headers[i] ?? '';
      this.fontB(headerFontSize);
      const headerTextH = Math.ceil(this.doc.heightOfString(headerText, { width: cw - 4, lineBreak: false }));
      const headerY = y + Math.max(1, Math.floor((headerH - headerTextH) / 2));
      this.doc.fillColor(COLORS.text).text(headerText, cx + 2, headerY, {
        width: cw - 4,
        align: i === 4 ? 'left' : 'center',
        lineBreak: false,
        ellipsis: true,
      });
      cx += cw;
    }
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const vals = [row.qty, row.name, row.tox, row.time, row.effect, row.wt, row.price];
      let rx = x;
      for (let c = 0; c < cols.length; c += 1) {
        const cw = cols[c]!;
        this.fontR(c === 4 ? 6.0 : 6.2);
        this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 2, cy + 1, {
          width: cw - 4,
          height: rowH - 2,
          align: c === 1 || c === 4 ? 'left' : 'center',
        });
        rx += cw;
      }
      cy += rowH;
    }
    return h;
  }
  private drawMagicSummaryCompact(x: number, y: number, w: number, table: Table): number {
    const headerH = PAGE.headerH;
    const srcRows = table.rows.map((r) => ({
      type: (r.cells[0] ?? '').trim(),
      name: (r.cells[1] ?? '').trim(),
      element: (r.cells[2] ?? '').trim(),
      vigor: (r.cells[3] ?? '').trim(),
      vigorKeep: (r.cells[4] ?? '').trim(),
      damage: (r.cells[5] ?? '').trim(),
      time: (r.cells[6] ?? '').trim(),
      distance: (r.cells[7] ?? '').trim(),
      size: (r.cells[8] ?? '').trim(),
      form: (r.cells[9] ?? '').trim(),
    }));
    const totalRows = Math.max(srcRows.length + 3, 3);
    const rows = [
      ...srcRows,
      ...new Array(Math.max(0, totalRows - srcRows.length)).fill(null).map(() => ({
        type: '',
        name: '',
        element: '',
        vigor: '',
        vigorKeep: '',
        damage: '',
        time: '',
        distance: '',
        size: '',
        form: '',
      })),
    ];
    const headers = (table.columns.length >= 10
      ? table.columns
      : ['ТИП', 'НАЗВАНИЕ', 'ЭЛЕМЕНТ', 'ВЫН', 'ВЫН+', 'УРОН', 'ВРЕМЯ', 'ДИСТ', 'РАЗМЕР', 'ФОРМА'])
      .map((h) => String(h || '').toUpperCase());

    const fitDefs: Array<{ key: keyof (typeof rows)[number]; header: string; min: number }> = [
      { key: 'type', header: headers[0] ?? 'ТИП', min: 32 },
      { key: 'element', header: headers[2] ?? 'ЭЛЕМЕНТ', min: 34 },
      { key: 'vigor', header: headers[3] ?? 'ВЫН', min: 22 },
      { key: 'vigorKeep', header: headers[4] ?? 'ВЫН+', min: 24 },
      { key: 'damage', header: headers[5] ?? 'УРОН', min: 28 },
      { key: 'time', header: headers[6] ?? 'ВРЕМЯ', min: 28 },
      { key: 'distance', header: headers[7] ?? 'ДИСТ', min: 26 },
      { key: 'size', header: headers[8] ?? 'РАЗМЕР', min: 30 },
      { key: 'form', header: headers[9] ?? 'ФОРМА', min: 46 },
    ];
    const fitWidths = fitDefs.map((d) => {
      this.fontB(6.5);
      let mw = Math.max(d.min, Math.ceil(this.doc.widthOfString(d.header)) + 6);
      this.fontR(6.2);
      for (const row of rows) mw = Math.max(mw, Math.ceil(this.doc.widthOfString(String(row[d.key] || ''))) + 6);
      return mw;
    });
    const nonNameW = fitWidths.reduce((a, v) => a + v, 0);
    const nameW = Math.max(90, w - nonNameW);
    const rowHeights = rows.map((row) => {
      this.fontR(6.2);
      const nameH = Math.ceil(this.doc.heightOfString(row.name || '—', { width: nameW - 6 }));
      const formH = Math.ceil(this.doc.heightOfString(row.form || '—', { width: fitWidths[8]! - 6 }));
      return Math.max(12, Math.max(nameH, formH) + 1);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.headerMagicSummary);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();

    const cols = [fitWidths[0]!, nameW, ...fitWidths.slice(1)];
    const headerFontSize = 6.5;
    let cx = x;
    for (let i = 0; i < cols.length; i += 1) {
      const cw = cols[i]!;
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, y, cw, h).stroke();
      const headerText = headers[i] ?? '';
      this.fontB(headerFontSize);
      const headerTextH = Math.ceil(this.doc.heightOfString(headerText, { width: cw - 4, lineBreak: false }));
      const headerY = y + Math.max(1, Math.floor((headerH - headerTextH) / 2));
      this.doc.fillColor(COLORS.text).text(headerText, cx + 2, headerY, {
        width: cw - 4,
        align: i === 0 ? 'right' : 'left',
        lineBreak: false,
        ellipsis: true,
      });
      cx += cw;
    }
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const vals = [row.type, row.name, row.element, row.vigor, row.vigorKeep, row.damage, row.time, row.distance, row.size, row.form];
      let rx = x;
      for (let c = 0; c < cols.length; c += 1) {
        const cw = cols[c]!;
        this.fontR(6.2);
        this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 2, cy + 1, {
          width: cw - 4,
          height: rowH - 2,
          align: c === 0 ? 'right' : 'left',
        });
        rx += cw;
      }
      cy += rowH;
    }
    return h;
  }
  private table(x: number, y: number, w: number, table: Table, weights: number[], fill: string, maxRows?: number) {
    const rows = typeof maxRows === 'number' ? table.rows.slice(0, maxRows) : table.rows;
    const headH = 12, rowH = 10, h = PAGE.headerH + headH + Math.max(1, rows.length) * rowH;
    this.shell(x, y, w, h, table.title, fill);
    const total = weights.reduce((a, b) => a + b, 0);
    const colW = weights.map((k) => (w * k) / total);
    const ty = y + PAGE.headerH;
    this.doc.rect(x, ty, w, headH).fill(COLORS.headerDefault);
    let cx = x;
    for (let c = 0; c < colW.length; c += 1) {
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, ty, colW[c]!, headH + Math.max(1, rows.length) * rowH).stroke();
      this.fontB(6.8); this.doc.fillColor(COLORS.text).text(table.columns[c] ?? '', cx + 3, ty + 1, { width: colW[c]! - 6, lineBreak: false, ellipsis: true });
      cx += colW[c]!;
    }
    let ry = ty + headH;
    for (let r = 0; r < Math.max(1, rows.length); r += 1) {
      // Keep table bodies white (no zebra fill) to match the reference style.
      const row = rows[r];
      let rx = x;
      for (let c = 0; c < colW.length; c += 1) {
        this.fontR(6.8);
        this.doc.fillColor(COLORS.text).text(row?.cells[c] ?? '', rx + 3, ry + 1, { width: colW[c]! - 6, height: rowH - 2, ellipsis: true });
        rx += colW[c]!;
      }
      ry += rowH;
    }
    return h;
  }
  private flowTable(table: Table, weights: number[], fill: string) {
    let idx = 0;
    while (idx < table.rows.length || (idx === 0 && table.rows.length === 0)) {
      const rowCapacity = Math.max(1, Math.floor((this.bottom() - this.y - PAGE.headerH - 18) / 12));
      this.ensure(PAGE.headerH + 18 + Math.min(3, Math.max(1, rowCapacity)) * 12);
      const chunkRows = table.rows.slice(idx, idx + rowCapacity);
      const title = idx === 0 ? table.title : `${table.title} (cont.)`;
      const h = this.table(this.x, this.y, this.w, { ...table, title, rows: chunkRows }, weights, fill);
      this.y += h + 6;
      if (!chunkRows.length) break;
      idx += chunkRows.length;
    }
  }
  private notesStrip(title: string) {
    const left = this.bottom() - this.y;
    if (left < 70) return;
    const h = left;
    const w = (this.w - PAGE.gap * 2) / 3;
    for (let i = 0; i < 3; i += 1) {
      const x = this.x + i * (w + PAGE.gap);
      this.shell(x, this.y, w, h, title, COLORS.headerNotes);
      for (let ly = this.y + PAGE.headerH + 11; ly < this.y + h; ly += 12) {
        this.doc.moveTo(x, ly).lineTo(x + w, ly).strokeColor(COLORS.line).lineWidth(0.2).stroke();
      }
    }
    this.y += h;
  }
  private notesStripAt(x: number, y: number, w: number, h: number, title: string) {
    if (h < 50) return 0;
    const colW = (w - PAGE.gap * 2) / 3;
    for (let i = 0; i < 3; i += 1) {
      const bx = x + i * (colW + PAGE.gap);
      this.shell(bx, y, colW, h, title, COLORS.headerNotes);
      for (let ly = y + PAGE.headerH + 11; ly < y + h; ly += 12) {
        this.doc.moveTo(bx, ly).lineTo(bx + colW, ly).strokeColor(COLORS.line).lineWidth(0.2).stroke();
      }
    }
    return h;
  }

  private textWidth(txt: string, font: 'regular' | 'bold', size: number): number {
    if (font === 'bold') this.fontB(size); else this.fontR(size);
    return Math.ceil(this.doc.widthOfString(txt || ''));
  }

  private headerCellText(label: string): string {
    return String(label ?? '').toUpperCase().replace(/\s+/g, '\u00A0');
  }

  private headerCellWidth(label: string, size = 6.8): number {
    return this.textWidth(this.headerCellText(label), 'bold', size);
  }

  private drawRichInline(
    x: number,
    y: number,
    w: number,
    label: string,
    value: string,
    size = 6.9,
    lineH = 9,
  ): number {
    const tokens: RichToken[] = [
      { text: `${label}: `, bold: true, italic: false },
      ...parseRichInlineTokens(value),
    ];
    let cx = x;
    let cy = y;
    const xMax = x + w;
    const drawToken = (t: { text: string; bold: boolean; italic: boolean }) => {
      if (!t.text) return;
      const parts = t.text.split(/(\s+)/).filter((p) => p.length > 0);
      for (const part of parts) {
        const ww = this.textWidth(part, t.bold ? 'bold' : 'regular', size);
        const trimLeft = part.trimStart();
        const isOnlySpaces = trimLeft.length === 0;
        if (!isOnlySpaces && cx + ww > xMax && cx > x) {
          cx = x;
          cy += lineH;
        }
        if (t.bold) this.fontB(size); else this.fontR(size);
        this.doc.fillColor(COLORS.text).text(part, cx, cy, {
          width: ww + 1,
          lineBreak: false,
          oblique: t.italic,
        });
        cx += ww;
      }
    };
    for (const token of tokens) {
      if ('newline' in token) {
        cx = x;
        cy += lineH;
        continue;
      }
      drawToken(token);
    }
    return cy - y + lineH;
  }

  private measureRichTextHeight(
    w: number,
    value: string,
    size = 6.2,
    lineH = 8,
  ): number {
    const tokens = parseRichInlineTokens(value);
    let cx = 0;
    let lines = 1;
    for (const token of tokens) {
      if ('newline' in token) {
        lines += 1;
        cx = 0;
        continue;
      }
      const parts = token.text.split(/(\s+)/).filter((p) => p.length > 0);
      for (const part of parts) {
        const ww = this.textWidth(part, token.bold ? 'bold' : 'regular', size);
        const onlySpaces = part.trim().length === 0;
        if (!onlySpaces && cx + ww > w && cx > 0) {
          cx = 0;
          lines += 1;
        }
        cx += ww;
      }
    }
    return Math.max(lineH, lines * lineH);
  }

  private drawRichText(
    x: number,
    y: number,
    w: number,
    value: string,
    size = 6.2,
    lineH = 8,
    color = COLORS.muted,
  ): number {
    const tokens = parseRichInlineTokens(value);
    const xMax = x + w;
    let cx = x;
    let cy = y;
    for (const token of tokens) {
      if ('newline' in token) {
        cx = x;
        cy += lineH;
        continue;
      }
      const parts = token.text.split(/(\s+)/).filter((p) => p.length > 0);
      for (const part of parts) {
        const ww = this.textWidth(part, token.bold ? 'bold' : 'regular', size);
        const onlySpaces = part.trim().length === 0;
        if (!onlySpaces && cx + ww > xMax && cx > x) {
          cx = x;
          cy += lineH;
        }
        if (token.bold) this.fontB(size); else this.fontR(size);
        this.doc.fillColor(color).text(part, cx, cy, {
          width: ww + 1,
          lineBreak: false,
          oblique: token.italic,
        });
        cx += ww;
      }
    }
    return cy - y + lineH;
  }

  private normalizeMagicRows(
    headers: string[],
    rows: MagicTableRowVm[],
    ensureBlankMainRow: boolean,
  ): MagicTableRowVm[] {
    if (rows.length > 0) return rows;
    if (!ensureBlankMainRow) return [];
    return [{ cells: new Array(headers.length).fill('') }];
  }

  private measureMagicTableCardHeight(
    w: number,
    headers: string[],
    rows: MagicTableRowVm[],
    ensureBlankMainRow: boolean,
    wrappedMainCols: number[] = [],
  ): number {
    const ix = w - 8;
    const safeRows = this.normalizeMagicRows(headers, rows, ensureBlankMainRow);
    const colW = this.fitAllExceptLastByContent(Math.max(20, ix), headers, safeRows.map((r) => r.cells));
    const wrappedSet = new Set(wrappedMainCols);
    const mainLineH = this.measureGeneralGearCellLineHeight(6.4);
    const mainRowsH = safeRows.reduce((sum, row) => {
      let mainH = Math.max(11, mainLineH + 2);
      for (let i = 0; i < colW.length; i += 1) {
        if (!wrappedSet.has(i)) continue;
        const cellText = String(row.cells[i] ?? '');
        const hCell = Math.ceil(
          this.doc.heightOfString(cellText, { width: Math.max(12, colW[i]! - 6), lineGap: 0 }),
        ) + 4;
        mainH = Math.max(mainH, hCell);
      }
      const tooltip = (row.tooltip ?? '').trim();
      const tooltipH = tooltip ? Math.max(11, this.measureRichTextHeight(Math.max(12, ix - 6), tooltip, 6.2, 8) + 2) : 0;
      return sum + mainH + tooltipH;
    }, 0);
    const headerH = 12;
    const tableH = headerH + mainRowsH;
    return PAGE.headerH + 4 + tableH + 4;
  }

  private drawMagicTableCard(
    x: number,
    y: number,
    w: number,
    title: string,
    fill: string,
    headers: string[],
    rows: MagicTableRowVm[],
    ensureBlankMainRow: boolean,
    wrappedMainCols: number[] = [],
    centerBodyCols: number[] = [],
    leftHeaderCols: number[] = [],
  ): number {
    const h = this.measureMagicTableCardHeight(w, headers, rows, ensureBlankMainRow, wrappedMainCols);
    this.shell(x, y, w, h, title, fill);
    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    const iw = Math.max(20, w - 8);
    const safeRows = this.normalizeMagicRows(headers, rows, ensureBlankMainRow);
    const colW = this.fitAllExceptLastByContent(iw, headers, safeRows.map((r) => r.cells));
    const headerAlign: Array<'left' | 'center' | 'right'> = headers.map((_, i) =>
      leftHeaderCols.includes(i) ? 'left' : 'center',
    );
    const centerSet = new Set(centerBodyCols);
    const headerH = this.drawHeaderRow(ix, iy, colW, headers, headerAlign);
    const wrappedSet = new Set(wrappedMainCols);
    const mainLineH = this.measureGeneralGearCellLineHeight(6.4);
    const rowMetrics = safeRows.map((row) => {
      let mainH = Math.max(11, mainLineH + 2);
      for (let i = 0; i < colW.length; i += 1) {
        if (!wrappedSet.has(i)) continue;
        const cellText = String(row.cells[i] ?? '');
        const hCell = Math.ceil(
          this.doc.heightOfString(cellText, { width: Math.max(12, colW[i]! - 6), lineGap: 0 }),
        ) + 4;
        mainH = Math.max(mainH, hCell);
      }
      const tooltip = (row.tooltip ?? '').trim();
      const tooltipH = tooltip ? Math.max(11, this.measureRichTextHeight(Math.max(12, iw - 6), tooltip, 6.2, 8) + 2) : 0;
      return { mainH, tooltipH, tooltip };
    });
    const tableH = headerH + rowMetrics.reduce((sum, m) => sum + m.mainH + m.tooltipH, 0);

    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    let ry = iy + headerH;
    for (let r = 0; r < safeRows.length; r += 1) {
      const row = safeRows[r]!;
      const metrics = rowMetrics[r]!;
      const mainH = metrics.mainH;
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      for (let c = 0; c < colW.length; c += 1) {
        if (c > 0) this.doc.moveTo(cx, ry).lineTo(cx, ry + mainH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        this.fontR(6.4);
        const rawValue = String(row.cells[c] ?? '');
        if (wrappedSet.has(c)) {
          this.doc.fillColor(COLORS.text).text(rawValue, cx + 3, ry + 1, {
            width: colW[c]! - 6,
            lineGap: 0,
            paragraphGap: 0,
          });
        } else {
          const value = rawValue.replace(/\s*\r?\n\s*/g, ' ');
          const textY = ry + Math.max(1, Math.floor((mainH - mainLineH) / 2));
          this.doc.fillColor(COLORS.text).text(value, cx + 3, textY, {
            width: colW[c]! - 6,
            lineBreak: false,
            ellipsis: true,
            align: centerSet.has(c) ? 'center' : 'left',
          });
        }
        cx += colW[c]!;
      }
      ry += mainH;
      if (metrics.tooltip) {
        this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor('#d1d5db').lineWidth(0.25).stroke();
        this.drawRichText(ix + 3, ry + 1, Math.max(12, iw - 6), metrics.tooltip, 6.2, 8, COLORS.muted);
        ry += metrics.tooltipH;
      }
    }
    this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }

  private drawHeaderRow(
    x: number,
    y: number,
    colW: number[],
    labels: string[],
    align: 'left' | 'center' | 'right' | Array<'left' | 'center' | 'right'> = 'left',
    paddingX = 3,
  ) {
    const h = 12;
    this.doc.rect(x, y, colW.reduce((a, b) => a + b, 0), h).fill('#ffffff');
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(x, y, colW.reduce((a, b) => a + b, 0), h).stroke();
    let cx = x;
    this.fontB(6.8);
    for (let i = 0; i < colW.length; i += 1) {
      if (i > 0) this.doc.moveTo(cx, y).lineTo(cx, y + h).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const label = this.headerCellText(String(labels[i] ?? ''));
      const currentAlign = Array.isArray(align) ? (align[i] ?? 'left') : align;
      this.doc.fillColor(COLORS.text).text(label, cx + paddingX, y + 1, {
        width: colW[i]! - paddingX * 2,
        lineBreak: false,
        ellipsis: true,
        align: currentAlign,
      });
      cx += colW[i]!;
    }
    return h;
  }
  private notesStripAtCount(x: number, y: number, w: number, h: number, title: string, count: number) {
    if (h < 50 || count <= 0) return 0;
    const safeCount = Math.max(1, Math.floor(count));
    const colW = (w - PAGE.gap * (safeCount - 1)) / safeCount;
    for (let i = 0; i < safeCount; i += 1) {
      const bx = x + i * (colW + PAGE.gap);
      this.shell(bx, y, colW, h, title, COLORS.headerNotes);
      for (let ly = y + PAGE.headerH + 11; ly < y + h; ly += 12) {
        this.doc.moveTo(bx, ly).lineTo(bx + colW, ly).strokeColor(COLORS.line).lineWidth(0.2).stroke();
      }
    }
    return h;
  }
  private drawGeneralGearEmptyPairAt(
    x: number,
    y: number,
    w: number,
    h: number,
    title: string,
    headers: string[],
  ): void {
    const colGap = PAGE.gap;
    const colW = (w - colGap) / 2;
    const emptyRows: GeneralGearPageRow[] = [];
    this.drawGeneralGearHalfTable(x, y, colW, h, title, headers, emptyRows, 0);
    this.drawGeneralGearHalfTable(x + colW + colGap, y, colW, h, title, headers, emptyRows, 0);
  }

  private drawPage2SocialStatusCard(
    x: number,
    y: number,
    w: number,
    title: string,
    groups: SocialStatusGroup[],
    fearedSuffix: string,
  ): number {
    const safeGroups = groups.length > 0
      ? groups
      : [{ groupName: '—', statusLabel: '—', isFeared: false }];
    const values = safeGroups.map((g) => (g.isFeared ? `${g.statusLabel} ${fearedSuffix}` : g.statusLabel));
    const layout = this.computeSocialStatusLayout(Math.max(20, w - 8), safeGroups.map((g) => g.groupName), values);
    const outerH = PAGE.headerH + 4 + 12 + layout.rowH + 4;
    this.shell(x, y, w, outerH, title, COLORS.headerSocial);
    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    const iw = w - 8;
    const colW = layout.colW;
    const headerH = this.drawHeaderRow(ix, iy, colW, safeGroups.map((g) => g.groupName));
    const rowH = layout.rowH;
    const rowY = iy + headerH;
    const tableH = headerH + rowH;
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    this.doc.moveTo(ix, rowY).lineTo(ix + iw, rowY).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    let cx = ix;
    for (let i = 0; i < colW.length; i += 1) {
      if (i > 0) this.doc.moveTo(cx, iy).lineTo(cx, rowY + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontR(6.8);
      this.doc.fillColor(COLORS.text).text(values[i] ?? '', cx + 3, rowY + 1, { width: Math.max(12, colW[i]! - 6), align: 'left' });
      cx += colW[i]!;
    }
    this.doc.moveTo(ix, rowY + rowH).lineTo(ix + iw, rowY + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return outerH;
  }

  private measurePage2SocialStatusCardHeight(w: number, headers: string[], values: string[]): number {
    const iw = Math.max(20, w - 8);
    const layout = this.computeSocialStatusLayout(iw, headers, values);
    return PAGE.headerH + 4 + 12 + layout.rowH + 4;
  }

  private computeSocialStatusLayout(
    innerW: number,
    headers: string[],
    values: string[],
  ): { colW: number[]; rowH: number } {
    const n = Math.max(1, headers.length);
    const cols = Array.from({ length: n }, (_, i) => i);
    const upHeaders = headers.map((h) => this.headerCellText(String(h ?? '')));
    const minWidths = cols.map((i) => {
      const headerW = this.textWidth(upHeaders[i] ?? '', 'bold', 6.8) + 6;
      const maxWordW = Math.max(
        0,
        ...String(values[i] ?? '')
          .split(/\s+/)
          .filter(Boolean)
          .map((word) => this.textWidth(word, 'regular', 6.8) + 6),
      );
      return Math.max(30, headerW, maxWordW);
    });

    const widths = minWidths.slice();
    const minSum = minWidths.reduce((a, b) => a + b, 0);
    if (minSum < innerW) {
      const add = (innerW - minSum) / n;
      for (let i = 0; i < n; i += 1) widths[i] += add;
    }

    const lineCountByHeight = (h: number): number => {
      const single = 6.8 * 1.18;
      return Math.max(1, Math.ceil(h / single));
    };

    const headerLines = (idx: number, width: number): number => {
      const h = this.doc.heightOfString(upHeaders[idx] ?? '', { width: Math.max(12, width - 6), lineBreak: true });
      return lineCountByHeight(h);
    };

    const valueLines = (idx: number, width: number): number => {
      const h = this.doc.heightOfString(values[idx] ?? '', { width: Math.max(12, width - 6), lineBreak: true });
      return lineCountByHeight(h);
    };

    const rebalance = () => {
      const step = 2;
      for (let loops = 0; loops < 300; loops += 1) {
        let target = -1;
        let targetScore = 0;
        for (let i = 0; i < n; i += 1) {
          const hl = headerLines(i, widths[i]!);
          const vl = valueLines(i, widths[i]!);
          const score = Math.max(0, hl - 1) * 100 + Math.max(0, vl - 2);
          if (score > targetScore) {
            targetScore = score;
            target = i;
          }
        }
        if (target < 0 || targetScore <= 0) break;

        let donor = -1;
        let donorExtra = 0;
        for (let j = 0; j < n; j += 1) {
          if (j === target) continue;
          const extra = widths[j]! - minWidths[j]!;
          if (extra < step) continue;
          const nextHeader = headerLines(j, widths[j]! - step);
          const nextValue = valueLines(j, widths[j]! - step);
          if (nextHeader <= 1 && nextValue <= 2 && extra > donorExtra) {
            donor = j;
            donorExtra = extra;
          }
        }
        if (donor < 0) {
          for (let j = 0; j < n; j += 1) {
            if (j === target) continue;
            const extra = widths[j]! - minWidths[j]!;
            if (extra < step) continue;
            const currHeader = headerLines(j, widths[j]!);
            const currValue = valueLines(j, widths[j]!);
            const nextHeader = headerLines(j, widths[j]! - step);
            const nextValue = valueLines(j, widths[j]! - step);
            const worsens =
              (nextHeader > 1 && nextHeader > currHeader) ||
              (nextValue > 2 && nextValue > currValue);
            if (!worsens && extra > donorExtra) {
              donor = j;
              donorExtra = extra;
            }
          }
        }
        if (donor < 0) break;
        widths[donor] -= step;
        widths[target] += step;
      }
    };
    rebalance();

    // Exact fit normalization to avoid right border drift from floating sum errors.
    const sum = widths.reduce((a, b) => a + b, 0);
    const diff = innerW - sum;
    if (Math.abs(diff) > 0.1) {
      widths[n - 1] += diff;
    }

    const rowH = Math.max(
      12,
      ...cols.map((i) => Math.ceil(this.doc.heightOfString(values[i] ?? '', { width: Math.max(12, widths[i]! - 6), lineBreak: true }) + 2)),
    );
    return { colW: widths, rowH };
  }

  private measureLoreCardHeight(w: number, title: string, blocks: LoreBlock[]): number {
    const bodyW = Math.max(20, w - 10);
    let h = PAGE.headerH + 8;
    if (!blocks.length) return h + 14;
    for (const b of blocks) {
      const lineH = this.measureRichInlineHeight(bodyW, b.label, b.value);
      h += lineH + 2;
    }
    return h + 4;
  }

  private measureRichInlineHeight(w: number, label: string, value: string): number {
    // Simulate drawRichInline line wraps using width calculations only.
    const tokens: RichToken[] = [{ text: `${label}: `, bold: true, italic: false }, ...parseRichInlineTokens(value)];
    const x = 0;
    const xMax = w;
    let cx = x;
    let lines = 1;
    const measureToken = (t: { text: string; bold: boolean; italic: boolean }) => {
      const parts = t.text.split(/(\s+)/).filter((p) => p.length > 0);
      for (const part of parts) {
        const ww = this.textWidth(part, t.bold ? 'bold' : 'regular', 6.9);
        const trimLeft = part.trimStart();
        const isOnlySpaces = trimLeft.length === 0;
        if (!isOnlySpaces && cx + ww > xMax && cx > x) {
          cx = x;
          lines += 1;
        }
        cx += ww;
      }
    };
    for (const token of tokens) {
      if ('newline' in token) {
        lines += 1;
        cx = x;
        continue;
      }
      measureToken(token);
    }
    return lines * 9;
  }

  private drawLoreCard(x: number, y: number, w: number, title: string, blocks: LoreBlock[]): number {
    const h = this.measureLoreCardHeight(w, title, blocks);
    this.shell(x, y, w, h, title, COLORS.headerPage2Blue);
    let cy = y + PAGE.headerH + 4;
    const bodyW = Math.max(20, w - 10);
    if (!blocks.length) {
      this.fontR(6.8);
      this.doc.fillColor(COLORS.muted).text('—', x + 5, cy, { width: bodyW, lineBreak: false, ellipsis: true });
      return h;
    }
    for (const b of blocks) {
      const used = this.drawRichInline(x + 5, cy, bodyW, b.label, b.value, 6.9, 9);
      cy += used + 2;
    }
    return h;
  }

  private maxWordWidth(v: string, kind: 'bold' | 'regular', size: number): number {
    return Math.max(
      0,
      ...String(v ?? '')
        .split(/\s+/)
        .filter(Boolean)
        .map((part) => this.textWidth(part, kind, size)),
    );
  }

  private fitFixedPlusFlexibleLast(
    totalWidth: number,
    preferredFixed: number[],
    minFixed: number[],
    minLast: number,
  ): number[] {
    const widths = preferredFixed.slice();
    const minF = minFixed.slice();
    const fixedSum = () => widths.reduce((a, b) => a + b, 0);
    let last = totalWidth - fixedSum();
    if (last < minLast) {
      let need = minLast - last;
      const reducible = widths.map((w, i) => Math.max(0, w - minF[i]!));
      let reducibleSum = reducible.reduce((a, b) => a + b, 0);
      if (reducibleSum > 0 && need > 0) {
        for (let i = 0; i < widths.length; i += 1) {
          const share = need * ((reducible[i] ?? 0) / reducibleSum);
          const cut = Math.min(reducible[i] ?? 0, share);
          widths[i] -= cut;
        }
        last = totalWidth - fixedSum();
        need = Math.max(0, minLast - last);
        if (need > 0) {
          for (let i = 0; i < widths.length && need > 0; i += 1) {
            const canCut = Math.max(0, widths[i]! - minF[i]!);
            const cut = Math.min(canCut, need);
            widths[i] -= cut;
            need -= cut;
          }
          last = totalWidth - fixedSum();
        }
      }
      if (last < minLast) {
        for (let i = 0; i < widths.length; i += 1) widths[i] = minF[i]!;
        last = Math.max(12, totalWidth - fixedSum());
      }
    }
    const out = [...widths, last];
    const sum = out.reduce((a, b) => a + b, 0);
    const diff = totalWidth - sum;
    if (Math.abs(diff) > 0.1) out[out.length - 1] = Math.max(12, out[out.length - 1]! + diff);
    return out;
  }

  private drawStyleCard(x: number, y: number, w: number, title: string, s: StyleTableVm, cols: { clothing: string; personality: string; hairStyle: string; affectations: string }): number {
    const h = this.measureStyleCardHeight(w, s, cols);
    this.shell(x, y, w, h, title, COLORS.headerPage2Blue);
    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    const iw = w - 8;
    const headers = [cols.clothing, cols.personality, cols.hairStyle, cols.affectations];
    const row = [s.clothing, s.personality, s.hairStyle, s.affectations];
    const row0 = (row[0] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const row1 = (row[1] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const row2 = (row[2] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const row3 = (row[3] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const pref0 = Math.max(this.headerCellWidth(headers[0]!, 6.8), this.textWidth(row0, 'regular', 6.8)) + 8;
    const pref1 = Math.max(this.headerCellWidth(headers[1]!, 6.8), this.textWidth(row1, 'regular', 6.8)) + 8;
    const pref2 = Math.max(this.headerCellWidth(headers[2]!, 6.8), this.textWidth(row2, 'regular', 6.8)) + 8;
    const min0 = Math.max(
      this.headerCellWidth(headers[0]!, 6.8),
      this.maxWordWidth(row0, 'regular', 6.8),
    ) + 8;
    const min1 = Math.max(
      this.headerCellWidth(headers[1]!, 6.8),
      this.maxWordWidth(row1, 'regular', 6.8),
    ) + 8;
    const min2 = Math.max(
      this.headerCellWidth(headers[2]!, 6.8),
      this.maxWordWidth(row2, 'regular', 6.8),
    ) + 8;
    const minLast = Math.max(
      44,
      this.maxWordWidth(this.headerCellText(headers[3]!), 'bold', 6.8) + 8,
      this.maxWordWidth(row3, 'regular', 6.8) + 8,
    );
    const colW = this.fitFixedPlusFlexibleLast(
      iw,
      [pref0, pref1, pref2],
      [Math.max(30, min0), Math.max(30, min1), Math.max(30, min2)],
      minLast,
    );
    const headerH = this.drawHeaderRow(ix, iy, colW, headers);
    const rowH = Math.max(
      12,
      ...colW.map((cw, idx) =>
        Math.ceil(this.doc.heightOfString(row[idx] ?? '', { width: Math.max(12, cw - 6), lineGap: 0 })) + 2,
      ),
    );
    const rowY = iy + headerH;
    const tableH = headerH + rowH;
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    this.doc.moveTo(ix, rowY).lineTo(ix + iw, rowY).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    let cx = ix;
    for (let i = 0; i < colW.length; i += 1) {
      if (i > 0) this.doc.moveTo(cx, iy).lineTo(cx, rowY + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontR(6.8);
      this.doc.fillColor(COLORS.text).text(row[i] ?? '', cx + 3, rowY + 1, { width: colW[i]! - 6, lineGap: 0 });
      cx += colW[i]!;
    }
    this.doc.moveTo(ix, rowY + rowH).lineTo(ix + iw, rowY + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }

  private measureStyleCardHeight(w: number, s: StyleTableVm, cols: { clothing: string; personality: string; hairStyle: string; affectations: string }): number {
    const iw = Math.max(20, w - 8);
    const headers = [cols.clothing, cols.personality, cols.hairStyle, cols.affectations];
    const row = [s.clothing, s.personality, s.hairStyle, s.affectations];
    const row0 = (row[0] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const row1 = (row[1] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const row2 = (row[2] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const row3 = (row[3] ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const pref0 = Math.max(this.headerCellWidth(headers[0]!, 6.8), this.textWidth(row0, 'regular', 6.8)) + 8;
    const pref1 = Math.max(this.headerCellWidth(headers[1]!, 6.8), this.textWidth(row1, 'regular', 6.8)) + 8;
    const pref2 = Math.max(this.headerCellWidth(headers[2]!, 6.8), this.textWidth(row2, 'regular', 6.8)) + 8;
    const min0 = Math.max(
      this.headerCellWidth(headers[0]!, 6.8),
      this.maxWordWidth(row0, 'regular', 6.8),
    ) + 8;
    const min1 = Math.max(
      this.headerCellWidth(headers[1]!, 6.8),
      this.maxWordWidth(row1, 'regular', 6.8),
    ) + 8;
    const min2 = Math.max(
      this.headerCellWidth(headers[2]!, 6.8),
      this.maxWordWidth(row2, 'regular', 6.8),
    ) + 8;
    const minLast = Math.max(
      44,
      this.maxWordWidth(this.headerCellText(headers[3]!), 'bold', 6.8) + 8,
      this.maxWordWidth(row3, 'regular', 6.8) + 8,
    );
    const colW = this.fitFixedPlusFlexibleLast(
      iw,
      [pref0, pref1, pref2],
      [Math.max(30, min0), Math.max(30, min1), Math.max(30, min2)],
      minLast,
    );
    const rowH = Math.max(
      12,
      ...colW.map((cw, idx) =>
        Math.ceil(this.doc.heightOfString(row[idx] ?? '', { width: Math.max(12, cw - 6), lineGap: 0 })) + 2,
      ),
    );
    return PAGE.headerH + 4 + 12 + rowH + 4;
  }

  private drawValuesCard(x: number, y: number, w: number, title: string, v: ValuesTableVm, cols: { valuedPerson: string; value: string; feelingsOnPeople: string }): number {
    const h = this.measureValuesCardHeight(w, v, cols);
    this.shell(x, y, w, h, title, COLORS.headerPage2Blue);
    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    const iw = w - 8;
    const headers = [cols.valuedPerson, cols.value, cols.feelingsOnPeople];
    const row = [v.valuedPerson, v.value, v.feelingsOnPeople];
    const pref0 = Math.max(this.headerCellWidth(headers[0]!, 6.8), this.textWidth(row[0]!, 'regular', 6.8)) + 8;
    const pref1 = Math.max(this.headerCellWidth(headers[1]!, 6.8), this.textWidth(row[1]!, 'regular', 6.8)) + 8;
    const min0 = Math.max(this.headerCellWidth(headers[0]!, 6.8), this.textWidth(row[0]!, 'regular', 6.8)) + 8;
    const min1 = Math.max(this.headerCellWidth(headers[1]!, 6.8), this.textWidth(row[1]!, 'regular', 6.8)) + 8;
    const minLast = Math.max(
      44,
      this.maxWordWidth(this.headerCellText(headers[2]!), 'bold', 6.8) + 8,
      this.maxWordWidth(row[2]!, 'regular', 6.8) + 8,
    );
    const colW = this.fitFixedPlusFlexibleLast(iw, [pref0, pref1], [Math.max(30, min0), Math.max(30, min1)], minLast);
    const headerH = this.drawHeaderRow(ix, iy, colW, headers);
    const rowH = Math.max(12, Math.ceil(this.doc.heightOfString(row[2] ?? '', { width: Math.max(12, colW[2]! - 6) })) + 2);
    const rowY = iy + headerH;
    const tableH = headerH + rowH;
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    this.doc.moveTo(ix, rowY).lineTo(ix + iw, rowY).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    let cx = ix;
    for (let i = 0; i < colW.length; i += 1) {
      if (i > 0) this.doc.moveTo(cx, iy).lineTo(cx, rowY + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontR(6.8);
      this.doc.fillColor(COLORS.text).text(row[i] ?? '', cx + 3, rowY + 1, { width: colW[i]! - 6 });
      cx += colW[i]!;
    }
    this.doc.moveTo(ix, rowY + rowH).lineTo(ix + iw, rowY + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }

  private measureValuesCardHeight(w: number, v: ValuesTableVm, cols: { valuedPerson: string; value: string; feelingsOnPeople: string }): number {
    const iw = Math.max(20, w - 8);
    const headers = [cols.valuedPerson, cols.value, cols.feelingsOnPeople];
    const row = [v.valuedPerson, v.value, v.feelingsOnPeople];
    const pref0 = Math.max(this.headerCellWidth(headers[0]!, 6.8), this.textWidth(row[0]!, 'regular', 6.8)) + 8;
    const pref1 = Math.max(this.headerCellWidth(headers[1]!, 6.8), this.textWidth(row[1]!, 'regular', 6.8)) + 8;
    const min0 = Math.max(this.headerCellWidth(headers[0]!, 6.8), this.textWidth(row[0]!, 'regular', 6.8)) + 8;
    const min1 = Math.max(this.headerCellWidth(headers[1]!, 6.8), this.textWidth(row[1]!, 'regular', 6.8)) + 8;
    const minLast = Math.max(
      44,
      this.maxWordWidth(this.headerCellText(headers[2]!), 'bold', 6.8) + 8,
      this.maxWordWidth(row[2]!, 'regular', 6.8) + 8,
    );
    const colW = this.fitFixedPlusFlexibleLast(iw, [pref0, pref1], [Math.max(30, min0), Math.max(30, min1)], minLast);
    const rowH = Math.max(12, Math.ceil(this.doc.heightOfString(row[2] ?? '', { width: Math.max(12, colW[2]! - 6) })) + 2);
    return PAGE.headerH + 4 + 12 + rowH + 4;
  }

  private drawLifePathCard(
    x: number,
    y: number,
    w: number,
    title: string,
    rows: LifeEventRow[],
    cols: { period: string; type: string; description: string },
  ): number {
    const h = this.measureLifePathCardHeight(w, rows, cols);
    this.shell(x, y, w, h, title, COLORS.headerPage2Blue);
    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    const iw = w - 8;
    const tableRows = rows.length ? rows : [{ period: '', type: '', description: '' }];
    const maxPeriod = Math.max(this.textWidth(cols.period, 'bold', 6.8), ...tableRows.map((r) => this.textWidth(r.period, 'regular', 6.8)));
    const maxType = Math.max(this.textWidth(cols.type, 'bold', 6.8), ...tableRows.map((r) => this.textWidth(r.type, 'regular', 6.8)));
    const periodW = Math.min(Math.max(38, maxPeriod + 8), Math.floor(iw * 0.26));
    const typeW = Math.min(Math.max(38, maxType + 8), Math.floor(iw * 0.26));
    const descW = Math.max(70, iw - periodW - typeW);
    const colW = [periodW, typeW, descW];
    const rowHeights = tableRows.map((row) => Math.max(12, Math.ceil(this.doc.heightOfString(row.description ?? '', { width: descW - 6 })) + 2));
    const headerH = this.drawHeaderRow(ix, iy, colW, [cols.period, cols.type, cols.description]);
    const tableH = headerH + rowHeights.reduce((a, b) => a + b, 0);
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    let ry = iy + headerH;
    for (let idx = 0; idx < tableRows.length; idx += 1) {
      const row = tableRows[idx]!;
      const rowH = rowHeights[idx]!;
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      const vals = [row.period, row.type, row.description];
      for (let i = 0; i < colW.length; i += 1) {
        if (i > 0) this.doc.moveTo(cx, iy).lineTo(cx, ry + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        this.fontR(6.8);
        this.doc.fillColor(COLORS.text).text(vals[i] ?? '', cx + 3, ry + 1, { width: colW[i]! - 6 });
        cx += colW[i]!;
      }
      ry += rowH;
    }
    this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }

  private measureLifePathCardHeight(
    w: number,
    rows: LifeEventRow[],
    cols: { period: string; type: string; description: string },
  ): number {
    const iw = Math.max(20, w - 8);
    const tableRows = rows.length ? rows : [{ period: '', type: '', description: '' }];
    const maxPeriod = Math.max(this.textWidth(cols.period, 'bold', 6.8), ...tableRows.map((r) => this.textWidth(r.period, 'regular', 6.8)));
    const maxType = Math.max(this.textWidth(cols.type, 'bold', 6.8), ...tableRows.map((r) => this.textWidth(r.type, 'regular', 6.8)));
    const periodW = Math.min(Math.max(38, maxPeriod + 8), Math.floor(iw * 0.26));
    const typeW = Math.min(Math.max(38, maxType + 8), Math.floor(iw * 0.26));
    const descW = Math.max(70, iw - periodW - typeW);
    const totalRowsH = tableRows.reduce(
      (acc, r) => acc + Math.max(12, Math.ceil(this.doc.heightOfString(r.description ?? '', { width: descW - 6 })) + 2),
      0,
    );
    return PAGE.headerH + 4 + 12 + totalRowsH + 4;
  }

  private fitColumnsWithFlexible(
    totalW: number,
    headers: string[],
    rows: string[][],
    flexIndex: number,
  ): number[] {
    const pref = headers.map((h, i) => {
      const headerW = this.headerCellWidth(h, 6.8) + 8;
      const rowW = Math.max(
        0,
        ...rows.map((r) => this.textWidth(r[i] ?? '', 'regular', 6.8) + 8),
      );
      return Math.max(24, headerW, rowW);
    });
    const minW = headers.map((h, i) => {
      const hw = this.maxWordWidth(this.headerCellText(h), 'bold', 6.8) + 8;
      const rw = Math.max(
        0,
        ...rows.map((r) => this.maxWordWidth(r[i] ?? '', 'regular', 6.8) + 8),
      );
      return Math.max(18, hw, rw);
    });

    const widths = pref.slice();
    const sum = widths.reduce((a, b) => a + b, 0);
    if (sum > totalW) {
      let need = sum - totalW;
      const idx = widths.map((_, i) => i).filter((i) => i !== flexIndex);
      for (let loop = 0; loop < 300 && need > 0.1; loop += 1) {
        let progressed = false;
        for (const i of idx) {
          if (need <= 0.1) break;
          const can = widths[i]! - minW[i]!;
          if (can <= 0) continue;
          const cut = Math.min(can, Math.max(0.5, need / idx.length));
          widths[i] -= cut;
          need -= cut;
          progressed = true;
        }
        if (!progressed) break;
      }
      if (need > 0.1) {
        const can = widths[flexIndex]! - minW[flexIndex]!;
        const cut = Math.min(can, need);
        widths[flexIndex] -= cut;
      }
    }
    const nonFlex = widths.reduce((a, b, i) => (i === flexIndex ? a : a + b), 0);
    widths[flexIndex] = Math.max(minW[flexIndex]!, totalW - nonFlex);
    const diff = totalW - widths.reduce((a, b) => a + b, 0);
    if (Math.abs(diff) > 0.1) widths[flexIndex] += diff;
    return widths;
  }

  private fitAllExceptLastByContent(
    totalW: number,
    headers: string[],
    rows: string[][],
    minLast = 44,
  ): number[] {
    const n = headers.length;
    if (n <= 1) return [totalW];
    const last = n - 1;
    const maxLineWidth = (value: string, kind: 'regular' | 'bold', size: number): number => {
      const lines = String(value ?? '')
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter((line) => line.length > 0);
      if (lines.length === 0) return 0;
      return Math.max(...lines.map((line) => this.textWidth(line, kind, size)));
    };
    const fixedPref = headers.slice(0, last).map((h, i) => {
      const headerW = this.headerCellWidth(h, 6.8) + 8;
      const rowW = Math.max(0, ...rows.map((r) => maxLineWidth(r[i] ?? '', 'regular', 6.8) + 8));
      return Math.max(24, headerW, rowW);
    });
    const fixedMin = headers.slice(0, last).map((h, i) => {
      const hw = this.maxWordWidth(this.headerCellText(h), 'bold', 6.8) + 8;
      const rw = Math.max(0, ...rows.map((r) => this.maxWordWidth((r[i] ?? '').replace(/\s*\r?\n\s*/g, ' '), 'regular', 6.8) + 8));
      return Math.max(16, hw, rw);
    });
    let fixed = fixedPref.slice();
    const sumFixed = () => fixed.reduce((a, b) => a + b, 0);
    if (sumFixed() + minLast > totalW) {
      let deficit = sumFixed() + minLast - totalW;
      for (let loop = 0; loop < 300 && deficit > 0.1; loop += 1) {
        let progressed = false;
        for (let i = 0; i < fixed.length; i += 1) {
          if (deficit <= 0.1) break;
          const can = fixed[i]! - fixedMin[i]!;
          if (can <= 0) continue;
          const cut = Math.min(can, Math.max(0.5, deficit / fixed.length));
          fixed[i] -= cut;
          deficit -= cut;
          progressed = true;
        }
        if (!progressed) break;
      }
    }
    const lastW = Math.max(12, totalW - sumFixed());
    const out = [...fixed, lastW];
    const diff = totalW - out.reduce((a, b) => a + b, 0);
    if (Math.abs(diff) > 0.1) out[last] += diff;
    return out;
  }

  private measureDataGridCardHeight(
    w: number,
    headers: string[],
    rows: string[][],
    flexIndex: number,
    rowHeightByColIndex?: number,
    fitAllExceptLastByContent?: boolean,
    tableInTable?: boolean,
  ): number {
    const iw = Math.max(20, w - 8);
    const safeRows = rows.length ? rows : [new Array(headers.length).fill('')];
    const colW = fitAllExceptLastByContent
      ? this.fitAllExceptLastByContent(iw, headers, safeRows)
      : this.fitColumnsWithFlexible(iw, headers, safeRows, flexIndex);
    const rowHeights = safeRows.map((row) => {
      if (typeof rowHeightByColIndex === 'number') {
        const idx = clamp(rowHeightByColIndex, 0, colW.length - 1);
        return Math.max(12, Math.ceil(this.doc.heightOfString(row[idx] ?? '', { width: Math.max(12, colW[idx]! - 6) })) + 2);
      }
      let maxH = 12;
      for (let i = 0; i < colW.length; i += 1) {
        const cellH = Math.ceil(this.doc.heightOfString(row[i] ?? '', { width: Math.max(12, colW[i]! - 6) })) + 2;
        maxH = Math.max(maxH, cellH);
      }
      return maxH;
    });
    const tableH = 12 + rowHeights.reduce((a, b) => a + b, 0);
    const outerPad = 0;
    const outerH = tableH + outerPad * 2;
    return PAGE.headerH + 4 + outerH + 4;
  }

  private drawDataGridCard(
    x: number,
    y: number,
    w: number,
    title: string,
    fill: string,
    headers: string[],
    rows: string[][],
    flexIndex: number,
    rowHeightByColIndex?: number,
    fitAllExceptLastByContent?: boolean,
    tableInTable?: boolean,
    cellPaddingX = 3,
  ): number {
    const h = this.measureDataGridCardHeight(w, headers, rows, flexIndex, rowHeightByColIndex, fitAllExceptLastByContent, tableInTable);
    this.shell(x, y, w, h, title, fill);
    const boxX = x + 4;
    const boxY = y + PAGE.headerH + 4;
    const boxW = w - 8;
    const outerPad = 0;
    const ix = boxX + outerPad;
    const iy = boxY + outerPad;
    const iw = boxW - outerPad * 2;
    const safeRows = rows.length ? rows : [new Array(headers.length).fill('')];
    const colW = fitAllExceptLastByContent
      ? this.fitAllExceptLastByContent(iw, headers, safeRows)
      : this.fitColumnsWithFlexible(iw, headers, safeRows, flexIndex);
    const headerH = this.drawHeaderRow(ix, iy, colW, headers, 'center', cellPaddingX);
    const rowHeights = safeRows.map((row) => {
      if (typeof rowHeightByColIndex === 'number') {
        const idx = clamp(rowHeightByColIndex, 0, colW.length - 1);
        return Math.max(12, Math.ceil(this.doc.heightOfString(row[idx] ?? '', { width: Math.max(12, colW[idx]! - 6) })) + 2);
      }
      let maxH = 12;
      for (let i = 0; i < colW.length; i += 1) {
        const cellH = Math.ceil(this.doc.heightOfString(row[i] ?? '', { width: Math.max(12, colW[i]! - 6) })) + 2;
        maxH = Math.max(maxH, cellH);
      }
      return maxH;
    });
    const tableH = headerH + rowHeights.reduce((a, b) => a + b, 0);
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    let ry = iy + headerH;
    for (let r = 0; r < safeRows.length; r += 1) {
      const row = safeRows[r]!;
      const rowH = rowHeights[r]!;
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      for (let c = 0; c < colW.length; c += 1) {
        if (c > 0) this.doc.moveTo(cx, iy).lineTo(cx, ry + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        this.fontR(6.8);
        const isWrapCol = typeof rowHeightByColIndex === 'number' && c === clamp(rowHeightByColIndex, 0, colW.length - 1);
        const cell = row[c] ?? '';
        const drawValue = isWrapCol ? cell : cell.replace(/\s*\r?\n\s*/g, ' ');
        this.doc.fillColor(COLORS.text).text(drawValue, cx + cellPaddingX, ry + 1, {
          width: colW[c]! - cellPaddingX * 2,
          lineBreak: isWrapCol,
          ellipsis: isWrapCol ? false : true,
        });
        cx += colW[c]!;
      }
      ry += rowH;
    }
    this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }

  private drawItemEffectsCard(x: number, y: number, w: number, title: string, rows: ItemEffectGlossaryRow[]): number {
    const safeRows = rows.length ? rows : [{ name: '', value: '' }];
    const iw = Math.max(20, w - 8);
    const rowHeights = safeRows.map((row) => {
      const textValue = row.value?.trim() ? `${row.name} — ${row.value}` : row.name;
      return Math.max(12, Math.ceil(this.doc.heightOfString(textValue, { width: iw - 6 })) + 2);
    });
    const tableH = rowHeights.reduce((a, b) => a + b, 0);
    const h = PAGE.headerH + 4 + tableH + 4;
    this.shell(x, y, w, h, title, COLORS.headerPage2Blue);
    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    let ry = iy;
    for (let i = 0; i < safeRows.length; i += 1) {
      const row = safeRows[i]!;
      const rowH = rowHeights[i]!;
      if (i > 0) this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const name = row.name?.trim() ?? '';
      const value = row.value?.trim() ?? '';
      const tail = value ? ` — ${value}` : '';
      if (name) {
        this.fontB(6.8);
        this.doc.fillColor(COLORS.text).text(name, ix + 3, ry + 1, {
          width: iw - 6,
          continued: true,
          lineBreak: false,
        });
        this.fontR(6.8);
        this.doc.fillColor(COLORS.text).text(tail, {
          width: iw - 6,
          lineBreak: true,
        });
      } else {
        this.fontR(6.8);
        this.doc.fillColor(COLORS.text).text(tail, ix + 3, ry + 1, {
          width: iw - 6,
        });
      }
      ry += rowH;
    }
    return h;
  }

  private measureEqualColumnsCardHeight(
    w: number,
    headers: string[],
    rows: string[][],
  ): number {
    const outerPad = 0;
    const boxW = Math.max(20, w - 8);
    const iw = Math.max(12, boxW - outerPad * 2);
    const safeRows = rows.length ? rows : [new Array(headers.length).fill('')];
    const base = iw / Math.max(1, headers.length);
    const colW = new Array(headers.length).fill(base);
    const diff = iw - colW.reduce((a, b) => a + b, 0);
    if (colW.length) colW[colW.length - 1] += diff;
    const rowHeights = safeRows.map((row) => {
      let maxH = 12;
      for (let i = 0; i < colW.length; i += 1) {
        const cellH = Math.ceil(this.doc.heightOfString(row[i] ?? '', { width: Math.max(12, colW[i]! - 6) })) + 2;
        maxH = Math.max(maxH, cellH);
      }
      return maxH;
    });
    const tableH = 12 + rowHeights.reduce((a, b) => a + b, 0);
    const outerH = tableH + outerPad * 2;
    return PAGE.headerH + 4 + outerH + 4;
  }

  private drawEqualColumnsCard(
    x: number,
    y: number,
    w: number,
    title: string,
    fill: string,
    headers: string[],
    rows: string[][],
  ): number {
    const h = this.measureEqualColumnsCardHeight(w, headers, rows);
    this.shell(x, y, w, h, title, fill);
    const outerPad = 0;
    const boxX = x + 4;
    const boxY = y + PAGE.headerH + 4;
    const boxW = w - 8;
    const ix = boxX + outerPad;
    const iy = boxY + outerPad;
    const iw = boxW - outerPad * 2;
    const safeRows = rows.length ? rows : [new Array(headers.length).fill('')];
    const base = iw / Math.max(1, headers.length);
    const colW = new Array(headers.length).fill(base);
    const diff = iw - colW.reduce((a, b) => a + b, 0);
    if (colW.length) colW[colW.length - 1] += diff;
    const headerH = this.drawHeaderRow(ix, iy, colW, headers, ['center', 'left', 'center', 'center', 'center']);
    const rowHeights = safeRows.map((row) => {
      let maxH = 12;
      for (let i = 0; i < colW.length; i += 1) {
        const cellH = Math.ceil(this.doc.heightOfString(row[i] ?? '', { width: Math.max(12, colW[i]! - 6) })) + 2;
        maxH = Math.max(maxH, cellH);
      }
      return maxH;
    });
    const tableH = headerH + rowHeights.reduce((a, b) => a + b, 0);
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    let ry = iy + headerH;
    for (let r = 0; r < safeRows.length; r += 1) {
      const row = safeRows[r]!;
      const rowH = rowHeights[r]!;
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      for (let c = 0; c < colW.length; c += 1) {
        if (c > 0) this.doc.moveTo(cx, ry).lineTo(cx, ry + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        this.fontR(6.8);
        this.doc.fillColor(COLORS.text).text((row[c] ?? '').replace(/\s*\r?\n\s*/g, ' '), cx + 3, ry + 1, {
          width: colW[c]! - 6,
          lineBreak: false,
          ellipsis: true,
          align: 'center',
        });
        cx += colW[c]!;
      }
      ry += rowH;
    }
    this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }

  private fitGeneralGearColumns(totalW: number, headers: string[], rows: GeneralGearPageRow[]): number[] {
    const rowMatrix = rows.map((r) => [r.amount, r.name, r.concealment, r.weight, r.price]);
    return this.fitColumnsWithFlexible(totalW, headers, rowMatrix, 1);
  }

  private measureGeneralGearRow(
    row: GeneralGearPageRow,
    nameColW: number,
  ): { rowH: number; nameLineH: number; descH: number } {
    const name = (row.name ?? '').replace(/\s*\r?\n\s*/g, ' ').trim() || ' ';
    const desc = (row.description ?? '').replace(/\s*\r?\n\s*/g, ' ').trim();
    const textW = Math.max(16, nameColW - 6);

    this.fontR(6.4);
    const nameLineH = Math.ceil(this.doc.heightOfString(name, {
      width: textW,
      lineBreak: false,
      ellipsis: true,
      lineGap: 0,
    }));

    let descH = 0;
    if (desc) {
      this.fontR(6.0);
      descH = Math.ceil(this.doc.heightOfString(desc, {
        width: textW,
        lineGap: 0,
        oblique: true,
      }));
    }

    const rowH = desc
      ? Math.max(12, 1 + nameLineH + 1 + descH + 1)
      : Math.max(11, 1 + nameLineH + 1);

    return { rowH, nameLineH, descH };
  }

  private measureGeneralGearCellLineHeight(fontSize = 6.4): number {
    this.fontR(fontSize);
    return Math.ceil(this.doc.heightOfString('0', {
      width: 12,
      lineBreak: false,
      lineGap: 0,
    }));
  }

  private generalGearRowHeight(row: GeneralGearPageRow, nameColW: number): number {
    return this.measureGeneralGearRow(row, nameColW).rowH;
  }

  private countGeneralGearRowsFit(
    w: number,
    h: number,
    headers: string[],
    rows: GeneralGearPageRow[],
    startIndex: number,
  ): number {
    const iw = w - 8;
    const tableH = Math.max(12, h - PAGE.headerH - 8);
    const colW = this.fitGeneralGearColumns(iw, headers, rows.length ? rows : [{
      amount: '',
      name: '',
      description: '',
      concealment: '',
      weight: '',
      price: '',
    }]);
    const headerH = 12;
    const tableBottom = tableH;
    let used = headerH;
    let index = startIndex;
    const nameColW = colW[1] ?? 120;
    while (index < rows.length) {
      const rowH = this.generalGearRowHeight(rows[index]!, nameColW);
      if (used + rowH > tableBottom) break;
      used += rowH;
      index += 1;
    }
    return index;
  }
  private estimateGeneralGearHalfUsage(
    w: number,
    h: number,
    headers: string[],
    rows: GeneralGearPageRow[],
    startIndex: number,
  ): { nextIndex: number; guideRows: number } {
    const iw = w - 8;
    const tableH = Math.max(12, h - PAGE.headerH - 8);
    const colW = this.fitGeneralGearColumns(iw, headers, rows.length ? rows : [{
      amount: '',
      name: '',
      description: '',
      concealment: '',
      weight: '',
      price: '',
    }]);
    const headerH = 12;
    let used = headerH;
    let index = startIndex;
    const nameColW = colW[1] ?? 120;
    while (index < rows.length) {
      const rowH = this.generalGearRowHeight(rows[index]!, nameColW);
      if (used + rowH > tableH) break;
      used += rowH;
      index += 1;
    }
    let guideRows = 0;
    let remaining = tableH - used;
    while (remaining >= 11) {
      guideRows += 1;
      remaining -= 11;
    }
    return { nextIndex: index, guideRows };
  }
  private estimateGeneralGearPairUsage(
    w: number,
    h: number,
    headers: string[],
    rows: GeneralGearPageRow[],
    startIndex: number,
  ): { nextIndex: number; guideRows: number } {
    const colGap = PAGE.gap;
    const colW = (w - colGap) / 2;
    const left = this.estimateGeneralGearHalfUsage(colW, h, headers, rows, startIndex);
    const right = this.estimateGeneralGearHalfUsage(colW, h, headers, rows, left.nextIndex);
    return {
      nextIndex: right.nextIndex,
      guideRows: left.guideRows + right.guideRows,
    };
  }

  private drawGeneralGearPairOnce(
    x: number,
    y: number,
    w: number,
    title: string,
    headers: string[],
    rows: GeneralGearPageRow[],
    startIndex: number,
  ): number {
    const colGap = PAGE.gap;
    const colW = (w - colGap) / 2;
    const pageH = this.bottom() - y;
    const leftX = x;
    const rightX = x + colW + colGap;
    const nextLeft = this.drawGeneralGearHalfTable(
      leftX,
      y,
      colW,
      pageH,
      title,
      headers,
      rows,
      startIndex,
    );
    const nextRight = this.drawGeneralGearHalfTable(
      rightX,
      y,
      colW,
      pageH,
      title,
      headers,
      rows,
      nextLeft,
    );
    return nextRight;
  }

  private drawGeneralGearHalfTable(
    x: number,
    y: number,
    w: number,
    h: number,
    title: string,
    headers: string[],
    rows: GeneralGearPageRow[],
    startIndex: number,
  ): number {
    this.shell(x, y, w, h, title, COLORS.headerPage2Blue);
    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    const iw = w - 8;
    const tableH = Math.max(12, h - PAGE.headerH - 8);
    const colW = this.fitGeneralGearColumns(iw, headers, rows.length ? rows : [{
      amount: '',
      name: '',
      description: '',
      concealment: '',
      weight: '',
      price: '',
    }]);
    const headerH = this.drawHeaderRow(ix, iy, colW, headers);
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    const tableBottom = iy + tableH;
    let ry = iy + headerH;
    let index = startIndex;

    const nameColW = colW[1] ?? 120;
    const normalCellLineH = this.measureGeneralGearCellLineHeight(6.4);

    const drawRow = (row: GeneralGearPageRow, rowH: number) => {
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      const metrics = this.measureGeneralGearRow(row, nameColW);
      for (let c = 0; c < colW.length; c += 1) {
        if (c > 0) this.doc.moveTo(cx, ry).lineTo(cx, ry + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        const cw = colW[c]!;
        if (c === 1) {
          const name = (row.name ?? '').replace(/\s*\r?\n\s*/g, ' ');
          const desc = (row.description ?? '').replace(/\s*\r?\n\s*/g, ' ');
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(name, cx + 3, ry + 1, { width: cw - 6, lineBreak: false, ellipsis: true });
          if (desc) {
            this.fontR(6.0);
            this.doc.fillColor(COLORS.muted).text(desc, cx + 3, ry + 1 + metrics.nameLineH + 1, {
              width: cw - 6,
              lineGap: 0,
              oblique: true,
            });
          }
        } else {
          const vals = [row.amount, row.name, row.concealment, row.weight, row.price];
          this.fontR(6.4);
          const v = (vals[c] ?? '').replace(/\s*\r?\n\s*/g, ' ');
          const ty = ry + Math.max(1, Math.floor((rowH - normalCellLineH) / 2));
          this.doc.fillColor(COLORS.text).text(v, cx + 2, ty, {
            width: cw - 4,
            align: 'center',
            lineBreak: false,
            ellipsis: true,
          });
        }
        cx += cw;
      }
      ry += rowH;
    };

    while (index < rows.length) {
      const row = rows[index]!;
      const rowH = this.generalGearRowHeight(row, nameColW);
      if (ry + rowH > tableBottom) break;
      drawRow(row, rowH);
      index += 1;
    }

    // Empty guide rows down to table bottom.
    while (ry + 11 <= tableBottom) {
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      for (let c = 0; c < colW.length; c += 1) {
        if (c > 0) this.doc.moveTo(cx, ry).lineTo(cx, ry + 11).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        cx += colW[c]!;
      }
      ry += 11;
    }
    // If remaining tail is shorter than one full row, still draw separators to the real table end.
    if (ry < tableBottom) {
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      for (let c = 0; c < colW.length; c += 1) {
        if (c > 0) this.doc.moveTo(cx, ry).lineTo(cx, tableBottom).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        cx += colW[c]!;
      }
    }
    this.doc.moveTo(ix, tableBottom).lineTo(ix + iw, tableBottom).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return index;
  }

  private drawGeneralGearPairsFlow(
    startY: number,
    title: string,
    headers: string[],
    realRows: GeneralGearPageRow[],
    startIndex = 0,
  ): void {
    const x = PAGE.margin;
    const w = this.doc.page.width - PAGE.margin * 2;
    const rows = realRows.length > 0
      ? realRows
      : [{
          amount: '',
          name: '',
          description: '',
          concealment: '',
          weight: '',
          price: '',
        } as GeneralGearPageRow];

    let gearIndex = this.drawGeneralGearPairOnce(x, startY, w, title, headers, rows, startIndex);
    const hasRealRows = realRows.length > 0;
    while (hasRealRows && gearIndex < rows.length) {
      this.doc.addPage();
      this.paintBg();
      gearIndex = this.drawGeneralGearPairOnce(x, PAGE.margin, w, title, headers, rows, gearIndex);
    }
  }

  private measureItemEffectsCardHeight(w: number, rows: ItemEffectGlossaryRow[]): number {
    const safeRows = rows.length ? rows : [{ name: '', value: '' }];
    const iw = Math.max(20, w - 8);
    const tableH = safeRows.reduce((acc, row) => {
      const textValue = row.value?.trim() ? `${row.name} — ${row.value}` : row.name;
      return acc + Math.max(12, Math.ceil(this.doc.heightOfString(textValue, { width: iw - 6 })) + 2);
    }, 0);
    return PAGE.headerH + 4 + tableH + 4;
  }

  private minWidthForTwoLine(text: string, kind: 'bold' | 'regular', size: number): number {
    const value = String(text ?? '').trim();
    if (!value) return 0;
    const words = value.split(/\s+/).filter(Boolean);
    if (words.length <= 1) return this.textWidth(value, kind, size);
    let best = this.textWidth(value, kind, size);
    for (let i = 1; i < words.length; i += 1) {
      const left = words.slice(0, i).join(' ');
      const right = words.slice(i).join(' ');
      const w = Math.max(this.textWidth(left, kind, size), this.textWidth(right, kind, size));
      if (w < best) best = w;
    }
    return best;
  }

  private wrapTextTwoLines(text: string, width: number, kind: 'bold' | 'regular', size: number): string {
    const value = String(text ?? '').trim();
    if (!value) return '';
    const words = value.split(/\s+/).filter(Boolean);
    const lines: string[] = [];
    let current = '';
    const fits = (s: string) => this.textWidth(s, kind, size) <= width;
    for (const word of words) {
      if (!current) {
        current = word;
        continue;
      }
      const next = `${current} ${word}`;
      if (fits(next)) {
        current = next;
      } else {
        lines.push(current);
        current = word;
      }
      if (lines.length === 2) break;
    }
    if (lines.length < 2 && current) lines.push(current);
    if (lines.length > 2) lines.length = 2;
    if (lines.length === 2) {
      const consumed = lines.join(' ').trim().split(/\s+/).length;
      if (consumed < words.length) lines[1] = `${lines[1]}…`;
    }
    return lines.join('\n');
  }

  private fitRecipeColumns(
    totalW: number,
    headers: string[],
    rows: RecipePageRow[],
    recipeNameColIndex: number,
    formulaColIndex: number,
  ): number[] {
    const colCount = headers.length;
    const pref = new Array<number>(colCount).fill(24);
    const minW = new Array<number>(colCount).fill(18);

    for (let c = 0; c < colCount; c += 1) {
      const headerLines = String(headers[c] ?? '')
        .split(/\r?\n/)
        .map((line) => this.textWidth(this.headerCellText(line), 'bold', 6.6));
      const headerW = (headerLines.length ? Math.max(...headerLines) : 0) + 8;
      let cellPref = 0;
      let cellMin = 0;
      if (c === formulaColIndex) {
        // FORMULA column is flexible: do not size it by content width.
        // Keep only a safe minimum so it can expand and consume the remaining space.
        cellPref = 0;
        cellMin = 28;
      } else {
        for (const row of rows) {
          const values = [
            row.amount,
            row.recipeGroup,
            row.recipeName,
            row.complexity,
            row.timeCraft,
            row.formulaEn,
            row.priceFormula,
            row.minimalIngredientsCost,
            row.timeEffect,
            row.toxicity,
            row.weightPotion,
            row.pricePotion,
          ];
          const v = values[c] ?? '';
          if (c === recipeNameColIndex) {
            cellPref = Math.max(cellPref, this.minWidthForTwoLine(v, 'regular', 6.3) + 8);
          } else {
            cellPref = Math.max(cellPref, this.textWidth(v.replace(/\s*\r?\n\s*/g, ' '), 'regular', 6.3) + 8);
          }
          cellMin = Math.max(cellMin, this.maxWordWidth(v.replace(/\s*\r?\n\s*/g, ' '), 'regular', 6.3) + 8);
        }
      }
      pref[c] = Math.max(24, headerW, cellPref);
      const headerMin = Math.max(
        0,
        ...String(headers[c] ?? '')
          .split(/\r?\n/)
          .map((line) => this.maxWordWidth(this.headerCellText(line), 'bold', 6.6)),
      ) + 8;
      minW[c] = Math.max(16, headerMin, cellMin);
    }

    const minCostColIndex = 7;
    minW[minCostColIndex] = Math.max(minW[minCostColIndex]!, this.textWidth('ИНГР.', 'bold', 6.6) + 8);
    pref[minCostColIndex] = Math.max(pref[minCostColIndex]!, minW[minCostColIndex]!);

    const widths = pref.slice();
    const fixedIndexes = widths.map((_, i) => i).filter((i) => i !== formulaColIndex);
    const minFormula = minW[formulaColIndex]!;
    const sumFixed = () => fixedIndexes.reduce((a, i) => a + widths[i]!, 0);
    let fixedSum = sumFixed();
    if (fixedSum + minFormula > totalW) {
      let need = fixedSum + minFormula - totalW;
      for (let loop = 0; loop < 400 && need > 0.1; loop += 1) {
        let progressed = false;
        for (const idx of fixedIndexes) {
          if (need <= 0.1) break;
          const can = widths[idx]! - minW[idx]!;
          if (can <= 0) continue;
          const cut = Math.min(can, Math.max(0.5, need / fixedIndexes.length));
          widths[idx] -= cut;
          need -= cut;
          progressed = true;
        }
        if (!progressed) break;
      }
      fixedSum = sumFixed();
    }
    widths[formulaColIndex] = Math.max(minFormula, totalW - fixedSum);
    const diff = totalW - widths.reduce((a, b) => a + b, 0);
    if (Math.abs(diff) > 0.1) widths[formulaColIndex] += diff;
    return widths;
  }

  private drawFormulaImagesCell(
    formulaEn: string,
    x: number,
    y: number,
    w: number,
    h: number,
    alchemyStyle: 'w1' | 'w2' = 'w2',
  ) {
    const tokens = tokenizeFormulaIngredients(formulaEn);
    if (!tokens.length) return;
    const icon = 11;
    const gap = 2;
    const totalW = tokens.length * icon + Math.max(0, tokens.length - 1) * gap;
    let cx = x + Math.max(2, Math.floor((w - totalW) / 2));
    const cy = y + Math.max(0, Math.round((h - icon) / 2));
    for (const token of tokens) {
      if (cx + icon > x + w - 2) break;
      const assetPath = formulaIngredientAssetPath(token, alchemyStyle);
      if (assetPath) {
        try {
          this.doc.image(assetPath, cx, cy, { fit: [icon, icon] });
        } catch {
          const short = token
            .split(/\s+/)
            .filter(Boolean)
            .map((p) => p[0] ?? '')
            .join('')
            .slice(0, 2)
            .toUpperCase();
          this.doc.lineWidth(0.25).strokeColor('#65748b').rect(cx, cy, icon, icon).stroke();
          this.fontB(4.8);
          this.doc.fillColor('#334155').text(short || '?', cx + 1, cy + 2, { width: icon - 2, align: 'center', lineBreak: false, ellipsis: true });
        }
      } else {
        const short = token
          .split(/\s+/)
          .filter(Boolean)
          .map((p) => p[0] ?? '')
          .join('')
          .slice(0, 2)
          .toUpperCase();
        this.doc.lineWidth(0.25).strokeColor('#65748b').rect(cx, cy, icon, icon).stroke();
        this.fontB(4.8);
        this.doc.fillColor('#334155').text(short || '?', cx + 1, cy + 2, { width: icon - 2, align: 'center', lineBreak: false, ellipsis: true });
      }
      cx += icon + gap;
    }
  }

  private drawIngredientIconCell(
    substanceEn: string,
    x: number,
    y: number,
    w: number,
    h: number,
    alchemyStyle: 'w1' | 'w2',
  ) {
    const token = String(substanceEn ?? '').trim();
    if (!token) return;
    const icon = 11;
    const cx = x + Math.max(1, Math.floor((w - icon) / 2));
    const cy = y + Math.max(0, Math.floor((h - icon) / 2) - 2);
    const assetPath = formulaIngredientAssetPath(token, alchemyStyle);
    if (assetPath) {
      try {
        this.doc.image(assetPath, cx, cy, { fit: [icon, icon] });
        return;
      } catch {
        // fallback below
      }
    }
    this.doc.lineWidth(0.25).strokeColor('#65748b').rect(cx, cy, icon, icon).stroke();
  }

  private fitBlueprintColumns(totalW: number, headers: string[], rows: BlueprintPageRow[]): number[] {
    const colCount = headers.length;
    const valuesByCol = rows.map((r) => [
      r.amount,
      r.name,
      r.craftLevel,
      r.difficultyCheck,
      r.timeCraft,
      r.components,
      r.itemDesc,
      r.priceComponents,
      r.price,
      r.priceItem,
    ]);
    const minW = new Array<number>(colCount).fill(16);
    const prefW = new Array<number>(colCount).fill(16);
    const flexCols = new Set([5, 6]); // Состав, Описание
    const fixedCols = [...Array(colCount).keys()].filter((i) => !flexCols.has(i));

    for (let c = 0; c < colCount; c += 1) {
      const headerLines = String(headers[c] ?? '').split(/\r?\n/).filter(Boolean);
      const headerPref = Math.max(...headerLines.map((line) => this.textWidth(this.headerCellText(line), 'bold', 6.5)), 0) + 8;
      const headerMin = Math.max(...headerLines.map((line) => this.maxWordWidth(this.headerCellText(line), 'bold', 6.5)), 0) + 8;
      let cellPref = 0;
      let cellMin = 0;
      for (const rowVals of valuesByCol) {
        const v = String(rowVals[c] ?? '').replace(/\s*\r?\n\s*/g, ' ');
        if (!v) continue;
        if (flexCols.has(c)) {
          cellPref = Math.max(cellPref, Math.min(180, this.minWidthForTwoLine(v, 'regular', 6.2) + 8));
        } else {
          cellPref = Math.max(cellPref, this.textWidth(v, 'regular', 6.2) + 8);
        }
        cellMin = Math.max(cellMin, this.maxWordWidth(v, 'regular', 6.2) + 8);
      }
      minW[c] = Math.max(16, headerMin, cellMin);
      prefW[c] = Math.max(minW[c]!, headerPref, cellPref);
    }

    const widths = prefW.slice();
    let fixedSum = fixedCols.reduce((sum, idx) => sum + widths[idx]!, 0);
    let minFixedSum = fixedCols.reduce((sum, idx) => sum + minW[idx]!, 0);
    const minFlexSum = minW[5]! + minW[6]!;

    if (minFixedSum + minFlexSum > totalW) {
      // aggressive shrink of fixed cols to minimum possible
      const over = minFixedSum + minFlexSum - totalW;
      if (over > 0) {
        // nothing to do; below assignment will clamp flex columns to min, fit best effort
      }
      fixedSum = minFixedSum;
      for (const idx of fixedCols) widths[idx] = minW[idx]!;
    } else if (fixedSum + minFlexSum > totalW) {
      let need = fixedSum + minFlexSum - totalW;
      for (let loop = 0; loop < 400 && need > 0.1; loop += 1) {
        let progressed = false;
        for (const idx of fixedCols) {
          if (need <= 0.1) break;
          const can = widths[idx]! - minW[idx]!;
          if (can <= 0) continue;
          const cut = Math.min(can, Math.max(0.4, need / fixedCols.length));
          widths[idx] -= cut;
          need -= cut;
          progressed = true;
        }
        if (!progressed) break;
      }
      fixedSum = fixedCols.reduce((sum, idx) => sum + widths[idx]!, 0);
    }

    const remaining = Math.max(minFlexSum, totalW - fixedSum);
    const w5Pref = prefW[5]!;
    const w6Pref = prefW[6]!;
    const prefFlexSum = Math.max(1, w5Pref + w6Pref);
    widths[5] = Math.max(minW[5]!, Math.floor((remaining * w5Pref) / prefFlexSum));
    widths[6] = Math.max(minW[6]!, remaining - widths[5]!);
    const diff = totalW - widths.reduce((a, b) => a + b, 0);
    widths[6] = Math.max(minW[6]!, widths[6]! + diff);
    return widths;
  }

  private drawBlueprintsSection(
    x: number,
    y: number,
    w: number,
    rowsIn: BlueprintPageRow[],
    tx: ReturnType<typeof tr>,
    extraEmptyRows: number,
  ): number {
    const rows = [...rowsIn, ...new Array(Math.max(0, extraEmptyRows)).fill(null).map(() => ({
      amount: '',
      name: '',
      group: '',
      craftLevel: '',
      difficultyCheck: '',
      timeCraft: '',
      components: '',
      itemDesc: '',
      priceComponents: '',
      price: '',
      priceItem: '',
    } as BlueprintPageRow))];
    const headers = [
      tx.page3.blueprintsCols.qty,
      tx.page3.blueprintsCols.name,
      tx.page3.blueprintsCols.craftLevel,
      tx.page3.blueprintsCols.difficultyCheck,
      tx.page3.blueprintsCols.timeCraft,
      tx.page3.blueprintsCols.components,
      tx.page3.blueprintsCols.itemDesc,
      tx.page3.blueprintsCols.priceComponents,
      tx.page3.blueprintsCols.price,
      tx.page3.blueprintsCols.priceItem,
    ];

    const ix = x + 4;
    const iy = y + PAGE.headerH + 4;
    const iw = w - 8;
    const colW = this.fitBlueprintColumns(iw, headers, rows);
    const headerLineH = 7.0;
    const headerH = Math.max(
      12,
      ...headers.map((h) => {
        const lines = String(h ?? '').toUpperCase().split(/\r?\n/).filter(Boolean);
        return Math.ceil(lines.length * headerLineH + 2);
      }),
    );
    const rowHeights = rows.map((r) => {
      const nameText = r.group ? `${r.name}\n${r.group}` : r.name;
      const nameH = nameText
        ? Math.ceil(this.doc.heightOfString(nameText, { width: Math.max(10, colW[1]! - 6), lineGap: 0 }))
        : 0;
      const compH = r.components
        ? Math.ceil(this.doc.heightOfString(r.components, { width: Math.max(12, colW[5]! - 6), lineGap: 0 }))
        : 0;
      const descH = r.itemDesc
        ? Math.ceil(this.doc.heightOfString(r.itemDesc, { width: Math.max(12, colW[6]! - 6), lineGap: 0 }))
        : 0;
      return Math.max(11, nameH + 2, compH + 2, descH + 2);
    });
    const tableH = headerH + rowHeights.reduce((a, b) => a + b, 0);
    const outerH = PAGE.headerH + 4 + tableH + 4;

    this.shell(x, y, w, outerH, tx.page3.blueprints, COLORS.headerBlueprints);
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
    this.doc.rect(ix, iy, iw, headerH).fill('#ffffff');
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, headerH).stroke();
    let hx = ix;
    for (let i = 0; i < colW.length; i += 1) {
      if (i > 0) this.doc.moveTo(hx, iy).lineTo(hx, iy + headerH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(6.5);
      const headerLines = String(headers[i] ?? '').toUpperCase().split(/\r?\n/).filter(Boolean);
      const blockH = headerLines.length * headerLineH;
      let hy = iy + Math.max(1, Math.floor((headerH - blockH) / 2));
      for (const line of headerLines) {
        this.doc.fillColor(COLORS.text).text(line, hx + 3, hy, {
          width: colW[i]! - 6,
          align: 'center',
          lineBreak: false,
          ellipsis: true,
        });
        hy += headerLineH;
      }
      hx += colW[i]!;
    }

    let ry = iy + headerH;
    for (let r = 0; r < rows.length; r += 1) {
      const row = rows[r]!;
      const rowH = rowHeights[r]!;
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      let cx = ix;
      const vals = [
        row.amount,
        row.name,
        row.craftLevel,
        row.difficultyCheck,
        row.timeCraft,
        row.components,
        row.itemDesc,
        row.priceComponents,
        row.price,
        row.priceItem,
      ];
      for (let c = 0; c < colW.length; c += 1) {
        const cw = colW[c]!;
        if (c > 0) this.doc.moveTo(cx, iy).lineTo(cx, ry + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        if (c === 1) {
          const nameText = row.group ? `${row.name}\n${row.group}` : row.name;
          this.fontR(6.2);
          this.doc.fillColor(COLORS.text).text(nameText, cx + 3, ry + 1, { width: cw - 6, lineGap: 0 });
        } else if (c === 5 || c === 6) {
          this.fontR(6.2);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', cx + 3, ry + 1, { width: cw - 6, lineGap: 0 });
        } else {
          this.fontR(6.2);
          const value = (vals[c] ?? '').replace(/\s*\r?\n\s*/g, ' ');
          const ty = ry + Math.max(1, Math.floor((rowH - 7) / 2));
          this.doc.fillColor(COLORS.text).text(value, cx + 2, ty, {
            width: cw - 4,
            lineBreak: false,
            ellipsis: true,
            align: 'center',
          });
        }
        cx += cw;
      }
      ry += rowH;
    }
    this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return outerH;
  }

  private fitComponentsColumns(totalW: number, headers: string[], rows: ComponentPageRow[]): number[] {
    const colCount = headers.length;
    const nameCol = 2;
    const fixedCols = [0, 1, 3, 4, 5];
    const minW = new Array<number>(colCount).fill(16);
    const prefW = new Array<number>(colCount).fill(16);

    for (let c = 0; c < colCount; c += 1) {
      const headerLines = String(headers[c] ?? '').split(/\r?\n/).filter(Boolean);
      const headerPref = Math.max(...headerLines.map((line) => this.textWidth(this.headerCellText(line), 'bold', 6.4)), 0) + 8;
      const headerMin = Math.max(...headerLines.map((line) => this.maxWordWidth(this.headerCellText(line), 'bold', 6.4)), 0) + 8;
      let cellPref = 0;
      let cellMin = 0;
      for (const row of rows) {
        const vals = [row.amount, row.substanceEn, row.name, row.harvestingComplexity, row.weight, row.price];
        const v = String(vals[c] ?? '').replace(/\s*\r?\n\s*/g, ' ');
        if (!v) continue;
        if (c === 1) {
          cellPref = Math.max(cellPref, 18);
          cellMin = Math.max(cellMin, 16);
        } else if (c === nameCol) {
          cellPref = Math.max(cellPref, Math.min(140, this.minWidthForTwoLine(v, 'regular', 6.2) + 8));
          cellMin = Math.max(cellMin, this.maxWordWidth(v, 'regular', 6.2) + 8);
        } else {
          cellPref = Math.max(cellPref, this.textWidth(v, 'regular', 6.2) + 8);
          cellMin = Math.max(cellMin, this.maxWordWidth(v, 'regular', 6.2) + 8);
        }
      }
      minW[c] = Math.max(16, headerMin, cellMin);
      prefW[c] = Math.max(minW[c]!, headerPref, cellPref);
    }

    const widths = prefW.slice();
    let fixedSum = fixedCols.reduce((sum, idx) => sum + widths[idx]!, 0);
    const minFixedSum = fixedCols.reduce((sum, idx) => sum + minW[idx]!, 0);
    if (fixedSum > totalW - minW[nameCol]!) {
      let need = fixedSum - (totalW - minW[nameCol]!);
      for (let loop = 0; loop < 400 && need > 0.1; loop += 1) {
        let progressed = false;
        for (const idx of fixedCols) {
          if (need <= 0.1) break;
          const can = widths[idx]! - minW[idx]!;
          if (can <= 0) continue;
          const cut = Math.min(can, Math.max(0.4, need / fixedCols.length));
          widths[idx] -= cut;
          need -= cut;
          progressed = true;
        }
        if (!progressed) break;
      }
      fixedSum = fixedCols.reduce((sum, idx) => sum + widths[idx]!, 0);
    }
    const clampedFixedSum = Math.max(minFixedSum, fixedSum);
    widths[nameCol] = Math.max(minW[nameCol]!, totalW - clampedFixedSum);
    let diff = totalW - widths.reduce((a, b) => a + b, 0);
    widths[nameCol] = Math.max(minW[nameCol]!, widths[nameCol]! + diff);

    // Final normalization: keep exact total width to avoid the last column drifting.
    let sum = widths.reduce((a, b) => a + b, 0);
    if (sum > totalW) {
      let need = sum - totalW;
      const reducibleOrder = [nameCol, ...fixedCols];
      for (let loop = 0; loop < 400 && need > 0.1; loop += 1) {
        let progressed = false;
        for (const idx of reducibleOrder) {
          if (need <= 0.1) break;
          const can = widths[idx]! - minW[idx]!;
          if (can <= 0) continue;
          const cut = Math.min(can, Math.max(0.2, need / reducibleOrder.length));
          widths[idx] -= cut;
          need -= cut;
          progressed = true;
        }
        if (!progressed) break;
      }
      sum = widths.reduce((a, b) => a + b, 0);
    }
    if (sum < totalW) {
      widths[nameCol] += totalW - sum;
      sum = totalW;
    }
    diff = totalW - sum;
    if (Math.abs(diff) > 0.01) {
      // Fallback to keep arithmetic exact.
      widths[widths.length - 1] = Math.max(minW[widths.length - 1]!, widths[widths.length - 1]! + diff);
    }
    return widths;
  }

  private drawComponentsTripleTables(
    x: number,
    y: number,
    w: number,
    tables: Array<{ rows: ComponentPageRow[] }>,
    tx: ReturnType<typeof tr>,
    alchemyStyle: 'w1' | 'w2',
    extraEmptyRows: number,
  ): number {
    const gap = 6;
    const tableCount = 3;
    const tableW = (w - gap * (tableCount - 1)) / tableCount;
    const normalizedRowsByTable = Array.from({ length: tableCount }, (_, idx) =>
      Array.isArray(tables[idx]?.rows) ? tables[idx]!.rows : [],
    );
    const maxDataRows = Math.max(0, ...normalizedRowsByTable.map((rows) => rows.length));
    const targetRows = Math.max(0, maxDataRows + Math.max(0, extraEmptyRows));
    const headers = [
      tx.page3.componentsCols.qty,
      tx.page3.componentsCols.sub,
      tx.page3.componentsCols.name,
      tx.page3.componentsCols.harvestingComplexity,
      tx.page3.componentsCols.weight,
      tx.page3.componentsCols.price,
    ];
    let maxH = 0;

    for (let t = 0; t < tableCount; t += 1) {
      const cx = x + t * (tableW + gap);
      const rows = normalizedRowsByTable[t] ?? [];
      const tableRows = [...rows];
      while (tableRows.length < targetRows) {
        tableRows.push({
          amount: '',
          substanceEn: '',
          name: '',
          harvestingComplexity: '',
          weight: '',
          price: '',
        });
      }
      const ix = cx;
      const iy = y;
      const iw = tableW;
      const outerPad = 3;
      const txX = ix + outerPad;
      const txY = iy + outerPad;
      const txW = iw - outerPad * 2;
      const colW = this.fitComponentsColumns(txW, headers, tableRows);
      const headerH = 12;
      const rowHeights = tableRows.map((r) => {
        const nameH = r.name ? Math.ceil(this.doc.heightOfString(r.name, { width: Math.max(10, colW[2]! - 6), lineGap: 0 })) : 0;
        return Math.max(13, nameH + 4);
      });
      const innerTableH = headerH + rowHeights.reduce((a, b) => a + b, 0);
      const outerH = innerTableH + outerPad * 2;
      maxH = Math.max(maxH, outerH);

      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, outerH).stroke();
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(txX, txY, txW, innerTableH).stroke();
      this.doc.rect(txX, txY, txW, headerH).fill('#ffffff');
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(txX, txY, txW, headerH).stroke();
      let hx = txX;
      for (let i = 0; i < colW.length; i += 1) {
        if (i > 0) this.doc.moveTo(hx, txY).lineTo(hx, txY + headerH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        this.fontB(6.4);
        this.doc.fillColor(COLORS.text).text(String(headers[i] ?? '').toUpperCase(), hx + 2, txY + 2, {
          width: colW[i]! - 4,
          align: 'center',
          lineBreak: false,
          ellipsis: true,
        });
        hx += colW[i]!;
      }

      let ry = txY + headerH;
      for (let r = 0; r < tableRows.length; r += 1) {
        const row = tableRows[r]!;
        const rowH = rowHeights[r]!;
        this.doc.moveTo(txX, ry).lineTo(txX + txW, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        let cx2 = txX;
        const vals = [row.amount, row.substanceEn, row.name, row.harvestingComplexity, row.weight, row.price];
        for (let c = 0; c < colW.length; c += 1) {
          const cw = colW[c]!;
          if (c > 0) this.doc.moveTo(cx2, ry).lineTo(cx2, ry + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
          if (c === 1) {
            this.drawIngredientIconCell(vals[c] ?? '', cx2 + 1, ry + 1, cw - 2, rowH - 2, alchemyStyle);
          } else if (c === 2) {
            this.fontR(6.2);
            this.doc.fillColor(COLORS.text).text(vals[c] ?? '', cx2 + 3, ry + 1, { width: cw - 6, lineGap: 0 });
          } else {
            this.fontR(6.2);
            const v = (vals[c] ?? '').replace(/\s*\r?\n\s*/g, ' ');
            const ty = ry + Math.max(1, Math.floor((rowH - 7) / 2));
            this.doc.fillColor(COLORS.text).text(v, cx2 + 2, ty, {
              width: cw - 4,
              align: 'center',
              lineBreak: false,
              ellipsis: true,
            });
          }
          cx2 += cw;
        }
        ry += rowH;
      }
      this.doc.moveTo(txX, ry).lineTo(txX + txW, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    }
    return maxH;
  }

  private drawPage3Recipes(vm: ReturnType<typeof buildVm>): number {
    this.doc.addPage();
    this.paintBg();
    const tx = vm.tx;
    const alchemyIconStyle: 'w1' | 'w2' = vm.alchemyIconStyle === 'w1' ? 'w1' : 'w2';
    const pdfTableSettings: PdfTablesSettingsVm =
      (vm.pdfTableSettings as PdfTablesSettingsVm | undefined) ?? DEFAULT_PDF_TABLE_SETTINGS_VM;
    const x = PAGE.margin;
    const y = PAGE.margin;
    const w = this.doc.page.width - PAGE.margin * 2;
    const recipes = Array.isArray(vm.page3Recipes) ? vm.page3Recipes : [];
    const recipeEmptyRows = pdfTableSettings.alchemyRecipes.emptyRows;
    const shouldRenderRecipes = recipes.length > 0 || pdfTableSettings.alchemyRecipes.showIfEmpty;
    let cy = y;
    if (shouldRenderRecipes) {
      const rows = [...recipes, ...new Array(Math.max(0, recipeEmptyRows)).fill(null).map(() => ({
        amount: '',
        recipeGroup: '',
        recipeName: '',
        complexity: '',
        timeCraft: '',
        formulaEn: '',
        priceFormula: '',
        minimalIngredientsCost: '',
        timeEffect: '',
        toxicity: '',
        recipeDescription: '',
        weightPotion: '',
        pricePotion: '',
      } as RecipePageRow))];
      const headers = [
        tx.page3.recipesCols.qty,
        tx.page3.recipesCols.recipeGroup,
        tx.page3.recipesCols.recipeName,
        tx.page3.recipesCols.complexity,
        tx.page3.recipesCols.timeCraft,
        tx.page3.recipesCols.formula,
        tx.page3.recipesCols.priceFormula,
        tx.page3.recipesCols.minimalIngredientsCost,
        tx.page3.recipesCols.timeEffect,
        tx.page3.recipesCols.toxicity,
        tx.page3.recipesCols.weightPotion,
        tx.page3.recipesCols.pricePotion,
      ];

      const ix = x + 4;
      const iy = y + PAGE.headerH + 4;
      const iw = w - 8;
      const recipeNameColIndex = 2;
      const formulaColIndex = 5;
      const colW = this.fitRecipeColumns(iw, headers, rows, recipeNameColIndex, formulaColIndex);

      const rowHeights = rows.map((r) => {
        const wrappedName = this.wrapTextTwoLines(r.recipeName || '', Math.max(10, colW[recipeNameColIndex]! - 6), 'regular', 6.2);
        const recipeNameH = wrappedName
          ? Math.ceil(this.doc.heightOfString(wrappedName, { width: Math.max(10, colW[recipeNameColIndex]! - 6), lineGap: 0 }))
          : 0;
        const effectMergedW = colW.slice(3).reduce((a, b) => a + b, 0);
        const effectH = r.recipeDescription
          ? Math.ceil(this.doc.heightOfString(r.recipeDescription, { width: Math.max(12, effectMergedW - 6), lineGap: 0 }))
          : 0;
        const formulaH = tokenizeFormulaIngredients(r.formulaEn).length > 0 ? 11 : 0;
        const topH = Math.max(RECIPE_PRIMARY_MIN_HEIGHT, recipeNameH + 2, formulaH + 2);
        const bottomH = Math.max(11, effectH + 2);
        return { topH, bottomH, totalH: topH + bottomH };
      });
      const headerLineH = 7.0;
      const headerH = Math.max(
        12,
        ...headers.map((h) => {
          const lines = String(h ?? '').toUpperCase().split(/\r?\n/).filter(Boolean);
          return Math.ceil(lines.length * headerLineH + 2);
        }),
      );
      const tableH = headerH + rowHeights.reduce((a, b) => a + b.totalH, 0);

      const legendPairs = FORMULA_INGREDIENT_NAMES.map((name) => {
        const label = name === 'Dog Tallow' ? tx.page3.formulaLegend.DogTallow : (tx.page3.formulaLegend as Record<string, string>)[name] ?? name;
        return { token: name, label };
      });
      let legendIcon = 10;
      let legendFont = 6.1;
      const hyphenPad = 2;
      const hyphenText = '-';
      const estimateCoreWidth = () => {
        const hyphenW = this.textWidth(hyphenText, 'regular', legendFont);
        return legendPairs.reduce(
          (sum, p) => sum + legendIcon + hyphenPad + hyphenW + hyphenPad + this.textWidth(p.label, 'regular', legendFont),
          0,
        );
      };
      let legendCoreW = estimateCoreWidth();
      while (legendCoreW > iw - 6 && legendIcon > 7) {
        legendIcon -= 1;
        legendFont = Math.max(5.2, legendFont - 0.2);
        legendCoreW = estimateCoreWidth();
      }
      const availableLegendW = Math.max(0, iw - 6);
      const autoGap = legendPairs.length > 1
        ? Math.max(0, (availableLegendW - legendCoreW) / (legendPairs.length - 1))
        : 0;
      const legendH = Math.max(12, legendIcon + 4);
      const outerH = PAGE.headerH + 4 + tableH + 2 + legendH + 4;

      this.shell(x, y, w, outerH, tx.page3.recipes, COLORS.headerRecipes);
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, tableH).stroke();
      this.doc.rect(ix, iy, iw, headerH).fill('#ffffff');
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(ix, iy, iw, headerH).stroke();
      let hx = ix;
      for (let i = 0; i < colW.length; i += 1) {
        if (i > 0) this.doc.moveTo(hx, iy).lineTo(hx, iy + headerH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        this.fontB(6.6);
        const headerLines = String(headers[i] ?? '').toUpperCase().split(/\r?\n/).filter(Boolean);
        const blockH = headerLines.length * headerLineH;
        let hy = iy + Math.max(1, Math.floor((headerH - blockH) / 2));
        for (const line of headerLines) {
          this.doc.fillColor(COLORS.text).text(line, hx + 3, hy, {
            width: colW[i]! - 6,
            align: 'center',
            lineBreak: false,
            ellipsis: true,
          });
          hy += headerLineH;
        }
        hx += colW[i]!;
      }

      let ry = iy + headerH;
      for (let r = 0; r < rows.length; r += 1) {
        const row = rows[r]!;
        const rowH = rowHeights[r]!;
        const topH = rowH.topH;
        const bottomH = rowH.bottomH;
        const totalH = rowH.totalH;
        this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        let cx = ix;
        const vals = [
          row.amount,
          row.recipeGroup,
          row.recipeName,
          row.complexity,
          row.timeCraft,
          row.formulaEn,
          row.priceFormula,
          row.minimalIngredientsCost,
          row.timeEffect,
          row.toxicity,
          row.weightPotion,
          row.pricePotion,
        ];
        for (let c = 0; c < colW.length; c += 1) {
          const cw = colW[c]!;
          if (c > 0) {
            const lineBottom = c <= 3 ? ry + totalH : ry + topH;
            this.doc.moveTo(cx, ry).lineTo(cx, lineBottom).strokeColor(COLORS.line).lineWidth(0.25).stroke();
          }
          if (c === formulaColIndex) {
            this.drawFormulaImagesCell(vals[c] ?? '', cx + 1, ry, cw - 2, topH, alchemyIconStyle);
          } else if (c === recipeNameColIndex) {
            this.fontR(6.2);
            const wrapped = this.wrapTextTwoLines(vals[c] ?? '', Math.max(10, cw - 6), 'regular', 6.2);
            const th = wrapped
              ? Math.ceil(this.doc.heightOfString(wrapped, { width: Math.max(10, cw - 6), lineGap: 0 }))
              : 0;
            const ty = ry + Math.max(1, Math.floor((topH - th) / 2));
            this.doc.fillColor(COLORS.text).text(wrapped, cx + 3, ty, {
              width: cw - 6,
              align: 'center',
              lineGap: 0,
            });
          } else {
            this.fontR(6.2);
            const value = (vals[c] ?? '').replace(/\s*\r?\n\s*/g, ' ');
            const cellH = c <= 1 ? totalH : topH;
            const ty = ry + Math.max(1, Math.floor((cellH - 7) / 2));
            this.doc.fillColor(COLORS.text).text(value, cx + 2, ty, {
              width: cw - 4,
              lineBreak: false,
              ellipsis: true,
              align: 'center',
            });
          }
          cx += cw;
        }
        const xAfterGroup = ix + colW[0]! + colW[1]!;
        this.doc.moveTo(xAfterGroup, ry + topH).lineTo(ix + iw, ry + topH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        const xAfterRecipe = xAfterGroup + colW[2]!;
        this.doc.moveTo(xAfterRecipe, ry + topH).lineTo(xAfterRecipe, ry + totalH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
        this.fontR(6.2);
        const effectLabelY = ry + topH + Math.max(1, Math.floor((bottomH - 7) / 2));
        this.doc.fillColor(COLORS.muted).text(tx.page3.recipesCols.recipeDescription.toUpperCase(), xAfterGroup + 2, effectLabelY, {
          width: colW[2]! - 4,
          align: 'center',
          lineBreak: false,
          ellipsis: true,
          oblique: true,
        });
        this.fontR(6.2);
        this.doc.fillColor(COLORS.muted).text(row.recipeDescription ?? '', xAfterRecipe + 3, ry + topH + 1, {
          width: iw - (xAfterRecipe - ix) - 6,
          oblique: true,
        });
        ry += totalH;
      }
      this.doc.moveTo(ix, ry).lineTo(ix + iw, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();

      const legendY = iy + tableH + 2;
      this.doc.moveTo(ix, legendY).lineTo(ix + iw, legendY).strokeColor('#666666').lineWidth(0.25).stroke();
      const ly = legendY + 1;
      let lx = ix + 3;
      for (const item of legendPairs) {
        const asset = formulaIngredientAssetPath(item.token, alchemyIconStyle);
        if (asset) {
          try { this.doc.image(asset, lx, ly + 1, { fit: [legendIcon, legendIcon] }); } catch {}
        }
        this.fontR(legendFont);
        const hyphenW = this.textWidth(hyphenText, 'regular', legendFont);
        const labelW = this.textWidth(item.label, 'regular', legendFont);
        let txX = lx + legendIcon;
        txX += hyphenPad;
        this.doc.fillColor(COLORS.text).text(hyphenText, txX, ly + 1, { width: hyphenW + 1, lineBreak: false, ellipsis: true });
        txX += hyphenW + hyphenPad;
        this.doc.fillColor(COLORS.text).text(item.label, txX, ly + 1, { width: labelW + 1, lineBreak: false, ellipsis: true });
        lx += legendIcon + hyphenPad + hyphenW + hyphenPad + labelW + autoGap;
      }
      cy = y + outerH + 6;
    }
    const blueprints = Array.isArray(vm.page3Blueprints) ? vm.page3Blueprints : [];
    const componentsTables = Array.isArray(vm.page3ComponentTables) ? vm.page3ComponentTables : [];
    const shouldRenderBlueprints = blueprints.length > 0 || pdfTableSettings.blueprints.showIfEmpty;
    if (shouldRenderBlueprints) {
      const estimateBlueprintH = (() => {
        const estimateRows = [...blueprints, ...new Array(Math.max(0, pdfTableSettings.blueprints.emptyRows)).fill(null).map(() => ({
          amount: '',
          name: '',
          group: '',
          craftLevel: '',
          difficultyCheck: '',
          timeCraft: '',
          components: '',
          itemDesc: '',
          priceComponents: '',
          price: '',
          priceItem: '',
        } as BlueprintPageRow))];
        return PAGE.headerH + 4 + 12 + estimateRows.length * 11 + 4;
      })();
      if (cy + estimateBlueprintH > this.bottom()) {
        this.doc.addPage();
        this.paintBg();
        cy = PAGE.margin;
      }
      const blueprintsH = this.drawBlueprintsSection(
        x,
        cy,
        w,
        blueprints,
        tx,
        pdfTableSettings.blueprints.emptyRows,
      );
      cy += blueprintsH + 6;
    }

    const hasComponentsData = componentsTables.some((t) => Array.isArray(t?.rows) && t.rows.length > 0);
    const shouldRenderComponents = hasComponentsData || pdfTableSettings.components.showIfEmpty;
    if (shouldRenderComponents) {
      const estimateComponentsH = (() => {
        const maxRows = Math.max(
          ...componentsTables.map((t) => (Array.isArray(t?.rows) ? t.rows.length : 0)),
          0,
        ) + Math.max(0, pdfTableSettings.components.emptyRows);
        return 12 + maxRows * 11;
      })();
      if (cy + estimateComponentsH > this.bottom()) {
        this.doc.addPage();
        this.paintBg();
        cy = PAGE.margin;
      }
      const componentsH = this.drawComponentsTripleTables(
        x,
        cy,
        w,
        componentsTables,
        tx,
        alchemyIconStyle,
        pdfTableSettings.components.emptyRows,
      );
      cy += componentsH + 6;
    }

    const moneyHeaders = [
      tx.page3.moneyCols.crowns,
      tx.page3.moneyCols.orens,
      tx.page3.moneyCols.florens,
      tx.page3.moneyCols.ducats,
      tx.page3.moneyCols.bizants,
      tx.page3.moneyCols.lintars,
    ];
    const moneyRow = [vm.page3Money?.crowns ?? '', '', '', '', '', ''];
    const vehicles = Array.isArray(vm.page3Vehicles) ? vm.page3Vehicles : [];
    const showOccupancy = vehicles.some((v) => (v.occupancy ?? '').trim() !== '');
    const vehicleHeaders = [
      tx.page3.transportCols.qty,
      tx.page3.transportCols.type,
      tx.page3.transportCols.name,
      tx.page3.transportCols.skill,
      tx.page3.transportCols.mod,
      tx.page3.transportCols.speed,
      tx.page3.transportCols.hp,
      tx.page3.transportCols.weight,
      tx.page3.transportCols.price,
      ...(showOccupancy ? [tx.page3.transportCols.occupancy] : []),
    ];
    const vehicleRows = vehicles.length
      ? vehicles.map((v) => [
          v.amount,
          v.subgroupName,
          v.vehicleName,
          v.base,
          v.controlModifier,
          v.speed,
          v.hp,
          v.weight,
          v.price,
          ...(showOccupancy ? [v.occupancy] : []),
        ])
      : [new Array(vehicleHeaders.length).fill('')];

    const supportH = this.drawPackedTableGroup(x, cy, w, '1/2', [
      {
        id: 'money',
        measure: (cw) => this.measureEqualColumnsCardHeight(cw, moneyHeaders, [moneyRow]),
        draw: (cx, cy2, cw) => this.drawEqualColumnsCard(cx, cy2, cw, tx.page3.money, COLORS.headerPage2Blue, moneyHeaders, [moneyRow]),
      },
      {
        id: 'transport',
        measure: (cw) => this.measureDataGridCardHeight(cw, vehicleHeaders, vehicleRows, 2, undefined, undefined, true),
        draw: (cx, cy2, cw) => this.drawDataGridCard(cx, cy2, cw, tx.page3.transport, COLORS.headerPage2Blue, vehicleHeaders, vehicleRows, 2, undefined, undefined, true, 1),
      },
    ], { maxMoves: 0, colGap: PAGE.gap, rowGap: 6 });
    cy += supportH + 6;
    const generalHeaders = [
      tx.page3.generalGearCols.qty,
      tx.page3.generalGearCols.name,
      tx.page3.generalGearCols.concealment,
      tx.page3.generalGearCols.weight,
      tx.page3.generalGearCols.price,
    ];
    const realGeneralRows = Array.isArray(vm.page3GeneralGear) && vm.page3GeneralGear.length > 0
      ? vm.page3GeneralGear
      : [];
    const generalRows = realGeneralRows.length > 0
      ? realGeneralRows
      : [{
          amount: '',
          name: '',
          description: '',
          concealment: '',
          weight: '',
          price: '',
        } as GeneralGearPageRow];
    this.page3FirstPairGuideRows = this.estimateGeneralGearPairUsage(
      w,
      this.bottom() - cy,
      generalHeaders,
      generalRows,
      0,
    ).guideRows;
    const nextIndex = this.drawGeneralGearPairOnce(
      x,
      cy,
      w,
      tx.page3.generalGear,
      generalHeaders,
      generalRows,
      0,
    );
    if (realGeneralRows.length === 0) {
      return 0;
    }
    return nextIndex;
  }

  private drawPage4Magic(
    vm: ReturnType<typeof buildVm>,
  ): void {
    const magic = vm.page4Magic as MagicPageVm | undefined;
    if (!magic || !magic.shouldRender) return;
    const pdfTableSettings: PdfTablesSettingsVm =
      (vm.pdfTableSettings as PdfTablesSettingsVm | undefined) ?? DEFAULT_PDF_TABLE_SETTINGS_VM;
    const tx = vm.tx;
    const pageW = this.doc.page.width - PAGE.margin * 2;
    const x = PAGE.margin;
    const mkRows = (
      rows: Array<{ cells: string[]; tooltip?: string }>,
      ensureBlankMainRow: boolean,
    ) => ({ rows, ensureBlankMainRow });

    const tables: Array<{
      title: string;
      fill: string;
      headers: string[];
      rows: MagicTableRowVm[];
      ensureBlankMainRow: boolean;
      wrappedMainCols?: number[];
      centerBodyCols?: number[];
      leftHeaderCols?: number[];
    }> = [];

    if (magic.showGifts && magic.giftsRows.length > 0) {
      const giftsHeaders = [
        tx.page4.gifts.colName,
        tx.page4.gifts.colGroup,
        tx.page4.gifts.colSl,
        tx.page4.gifts.colVigor,
        tx.page4.gifts.colCost,
      ];
      const giftsRows = magic.giftsRows.map((r) => ({
        cells: [r.name, r.group, r.sl, r.vigor, r.cost],
        tooltip: r.description,
      }));
      const giftSet = mkRows(giftsRows, false);
      tables.push({
        title: tx.page4.titles.gifts,
        fill: COLORS.headerMagicGifts,
        headers: giftsHeaders,
        rows: giftSet.rows,
        ensureBlankMainRow: giftSet.ensureBlankMainRow,
        centerBodyCols: [1, 2, 3],
        leftHeaderCols: [4],
      });
    }

    if (magic.showSpellsSigns && (magic.spellsSignsRows.length > 0 || pdfTableSettings.spellsSigns.showIfEmpty)) {
      const headers = [
        tx.page4.cols.name,
        tx.page4.cols.element,
        tx.page4.cols.staminaCast,
        tx.page4.cols.staminaKeeping,
        tx.page4.cols.effectTime,
        tx.page4.cols.damage,
        tx.page4.cols.distance,
        tx.page4.cols.form,
        tx.page4.cols.zoneSize,
      ];
      const rows = magic.spellsSignsRows.map((r) => ({
        cells: [r.name, r.element, r.staminaCast, r.staminaKeeping, r.effectTime, r.damage, r.distance, r.form, r.zoneSize],
        tooltip: r.tooltip,
      }));
      for (let i = 0; i < pdfTableSettings.spellsSigns.emptyRows; i += 1) {
        rows.push({ cells: new Array(headers.length).fill(''), tooltip: '' });
      }
      const set = mkRows(rows, false);
      tables.push({
        title: tx.page4.titles.spellsSigns,
        fill: COLORS.headerMagicSpells,
        headers,
        rows: set.rows,
        ensureBlankMainRow: set.ensureBlankMainRow,
        centerBodyCols: [1, 2, 3, 4, 5, 6],
        leftHeaderCols: [8],
      });
    }

    if (magic.showInvocations && (magic.invocationsRows.length > 0 || pdfTableSettings.invocations.showIfEmpty)) {
      const headers = [
        tx.page4.cols.name,
        tx.page4.cols.group,
        tx.page4.cols.staminaCast,
        tx.page4.cols.staminaKeeping,
        tx.page4.cols.damage,
        tx.page4.cols.distance,
        tx.page4.cols.zoneSize,
        tx.page4.cols.form,
        tx.page4.cols.effectTime,
      ];
      const rows = magic.invocationsRows.map((r) => ({
        cells: [r.name, r.group, r.staminaCast, r.staminaKeeping, r.damage, r.distance, r.zoneSize, r.form, r.effectTime],
        tooltip: r.tooltip,
      }));
      for (let i = 0; i < pdfTableSettings.invocations.emptyRows; i += 1) {
        rows.push({ cells: new Array(headers.length).fill(''), tooltip: '' });
      }
      const set = mkRows(rows, false);
      tables.push({
        title: magic.invocationsTitle,
        fill: magic.invocationsFill,
        headers,
        rows: set.rows,
        ensureBlankMainRow: set.ensureBlankMainRow,
        centerBodyCols: [1, 2, 3, 4, 5, 6],
        leftHeaderCols: [8],
      });
    }

    if (magic.showRituals && (magic.ritualsRows.length > 0 || pdfTableSettings.rituals.showIfEmpty)) {
      const headers = [
        tx.page4.cols.name,
        tx.page4.cols.level,
        tx.page4.cols.dc,
        tx.page4.cols.preparingTime,
        tx.page4.cols.staminaCast,
        tx.page4.cols.staminaKeeping,
        tx.page4.cols.zoneSize,
        tx.page4.cols.form,
        tx.page4.cols.effectTime,
        tx.page4.cols.ingredients,
      ];
      const rows = magic.ritualsRows.map((r) => ({
        cells: [r.name, r.level, r.dc, r.preparingTime, r.staminaCast, r.staminaKeeping, r.zoneSize, r.form, r.effectTime, r.ingredients],
        tooltip: r.tooltip,
      }));
      for (let i = 0; i < pdfTableSettings.rituals.emptyRows; i += 1) {
        rows.push({ cells: new Array(headers.length).fill(''), tooltip: '' });
      }
      const set = mkRows(rows, false);
      tables.push({
        title: tx.page4.titles.rituals,
        fill: COLORS.headerMagicRituals,
        headers,
        rows: set.rows,
        ensureBlankMainRow: set.ensureBlankMainRow,
        wrappedMainCols: [9],
        centerBodyCols: [1, 2, 3, 4, 5, 6, 7, 8],
        leftHeaderCols: [9],
      });
    }

    if (magic.showHexes && (magic.hexesRows.length > 0 || pdfTableSettings.hexes.showIfEmpty)) {
      const headers = [
        tx.page4.cols.name,
        tx.page4.cols.level,
        tx.page4.cols.staminaCast,
        tx.page4.cols.removeComponents,
        tx.page4.cols.removeInstructions,
      ];
      const rows = magic.hexesRows.map((r) => ({
        cells: [r.name, r.level, r.staminaCast, r.removeComponents, r.removeInstructions],
        tooltip: r.tooltip,
      }));
      for (let i = 0; i < pdfTableSettings.hexes.emptyRows; i += 1) {
        rows.push({ cells: new Array(headers.length).fill(''), tooltip: '' });
      }
      const set = mkRows(rows, false);
      tables.push({
        title: tx.page4.titles.hexes,
        fill: COLORS.headerMagicHexes,
        headers,
        rows: set.rows,
        ensureBlankMainRow: set.ensureBlankMainRow,
        wrappedMainCols: [3, 4],
        centerBodyCols: [1, 2],
      });
    }

    if (tables.length === 0) return;

    this.doc.addPage();
    this.paintBg();
    let cy = PAGE.margin;
    for (const table of tables) {
      const h = this.measureMagicTableCardHeight(
        pageW,
        table.headers,
        table.rows,
        table.ensureBlankMainRow,
        table.wrappedMainCols ?? [],
      );
      if (cy + h > this.bottom()) {
        this.doc.addPage();
        this.paintBg();
        cy = PAGE.margin;
      }
      this.drawMagicTableCard(
        x,
        cy,
        pageW,
        table.title,
        table.fill,
        table.headers,
        table.rows,
        table.ensureBlankMainRow,
        table.wrappedMainCols ?? [],
        table.centerBodyCols ?? [],
        table.leftHeaderCols ?? [],
      );
      cy += h + 6;
    }
  }

  private estimatePage3FirstPairGeneralGearIndex(vm: ReturnType<typeof buildVm>): { nextIndex: number; guideRows: number } {
    const probeDoc = new PDFDocument({ size: 'A4', margin: 0, compress: true });
    probeDoc.on('data', () => {});
    const probe = new Painter(probeDoc);
    const nextIndex = probe.drawPage3Recipes(vm);
    probeDoc.end();
    return { nextIndex, guideRows: probe.page3FirstPairGuideRows };
  }

  private drawPackedTableGroup(
    x: number,
    y: number,
    w: number,
    fraction: FractionalGroup,
    items: Array<{
      id: string;
      measure: (cw: number) => number;
      draw: (cx: number, cy: number, cw: number) => number;
    }>,
    opts?: { maxMoves?: number; colGap?: number; rowGap?: number },
  ): number {
    if (!items.length) return 0;
    const cols = fraction === '1/2' ? 2 : fraction === '1/3' ? 3 : 4;
    const colGap = opts?.colGap ?? PAGE.gap;
    const rowGap = opts?.rowGap ?? 6;
    const colW = (w - colGap * (cols - 1)) / cols;

    const baseOrder = items.map((_, i) => i);
    const candidates = enumerateOrdersWithMoves(baseOrder, Math.max(0, opts?.maxMoves ?? 0));

    let best:
      | {
          order: number[];
          placements: PackedPlacement[];
          totalH: number;
          sumH: number;
        }
      | null = null;

    for (const order of candidates) {
      const heights = Array.from({ length: cols }, () => 0);
      const placements: PackedPlacement[] = [];
      for (const itemIndex of order) {
        let col = 0;
        for (let i = 1; i < cols; i += 1) {
          if (heights[i]! < heights[col]!) col = i;
        }
        const h = Math.max(20, Math.ceil(items[itemIndex]!.measure(colW)));
        const py = heights[col]!;
        placements.push({ itemIndex, col, y: py, h });
        heights[col] = py + h + rowGap;
      }
      const totalH = Math.max(...heights) - rowGap;
      const sumH = heights.reduce((a, b) => a + b, 0);
      if (!best || totalH < best.totalH || (totalH === best.totalH && sumH < best.sumH)) {
        best = { order, placements, totalH, sumH };
      }
    }

    if (!best) return 0;
    for (const p of best.placements) {
      const cx = x + p.col * (colW + colGap);
      const cy = y + p.y;
      items[p.itemIndex]!.draw(cx, cy, colW);
    }
    return best.totalH;
  }

  private drawPage2(
    vm: ReturnType<typeof buildVm>,
    generalGearStartIndex: number,
    page3FirstPairGuideRows: number,
  ): { nextGeneralGearIndex: number; giftsInlinedOnPage2: boolean } {
    this.doc.addPage();
    this.paintBg();
    this.y = PAGE.margin;
    const tx = vm.tx;
    const items: Array<{
      id: string;
      measure: (cw: number) => number;
      draw: (cx: number, cy: number, cw: number) => number;
    }> = [
      {
        id: 'social',
        measure: (cw) => {
          const groups = (vm.page2SocialStatus ?? []).length
            ? (vm.page2SocialStatus ?? [])
            : [{ groupName: '—', statusLabel: '—', isFeared: false }];
          const values = groups.map((g) => (g.isFeared ? `${g.statusLabel} ${tx.page2.socialStatus.fearedSuffix}` : g.statusLabel));
          return this.measurePage2SocialStatusCardHeight(cw, groups.map((g) => g.groupName), values);
        },
        draw: (cx, cy, cw) => this.drawPage2SocialStatusCard(cx, cy, cw, tx.page2.socialStatusRace, vm.page2SocialStatus ?? [], tx.page2.socialStatus.fearedSuffix),
      },
      {
        id: 'lore',
        measure: (cw) => this.measureLoreCardHeight(cw, tx.page2.lore, vm.page2LoreBlocks ?? []),
        draw: (cx, cy, cw) => this.drawLoreCard(cx, cy, cw, tx.page2.lore, vm.page2LoreBlocks ?? []),
      },
    ];
    if (Array.isArray(vm.page2Siblings) && vm.page2Siblings.length > 0) {
      const siblingsHeaders = [
        tx.page2.siblingsCols.age,
        tx.page2.siblingsCols.gender,
        tx.page2.siblingsCols.attitude,
        tx.page2.siblingsCols.personality,
      ];
      const siblingsRows = vm.page2Siblings.map((s) => [s.age, s.gender, s.attitude, s.personality]);
      items.push({
        id: 'siblings',
        measure: (cw) => this.measureDataGridCardHeight(cw, siblingsHeaders, siblingsRows, 2, 2),
        draw: (cx, cy, cw) => this.drawDataGridCard(cx, cy, cw, tx.page2.siblings, COLORS.headerSiblings, siblingsHeaders, siblingsRows, 2, 2),
      });
    }
    items.push(
      {
        id: 'style',
        measure: (cw) => this.measureStyleCardHeight(cw, vm.page2StyleTable, tx.page2.styleCols),
        draw: (cx, cy, cw) => this.drawStyleCard(cx, cy, cw, tx.page2.style, vm.page2StyleTable, tx.page2.styleCols),
      },
      {
        id: 'values',
        measure: (cw) => this.measureValuesCardHeight(cw, vm.page2ValuesTable, tx.page2.valuesCols),
        draw: (cx, cy, cw) => this.drawValuesCard(cx, cy, cw, tx.page2.values, vm.page2ValuesTable, tx.page2.valuesCols),
      },
      {
        id: 'life',
        measure: (cw) => this.measureLifePathCardHeight(cw, vm.page2LifeEvents ?? [], tx.page2.lifeEventCols),
        draw: (cx, cy, cw) => this.drawLifePathCard(cx, cy, cw, tx.page2.lifePath, vm.page2LifeEvents ?? [], tx.page2.lifeEventCols),
      },
    );
    const packedH = this.drawPackedTableGroup(this.x, this.y, this.w, '1/2', items, { maxMoves: 2, colGap: PAGE.gap, rowGap: 6 });
    let cy = this.y + packedH + 6;

    let giftsInlinedOnPage2 = false;
    const pdfTableSettings: PdfTablesSettingsVm =
      (vm.pdfTableSettings as PdfTablesSettingsVm | undefined) ?? DEFAULT_PDF_TABLE_SETTINGS_VM;
    const allies = Array.isArray(vm.page2Allies) ? vm.page2Allies : [];
    const enemies = Array.isArray(vm.page2Enemies) ? vm.page2Enemies : [];
    const itemEffects = Array.isArray(vm.page2ItemEffects) ? vm.page2ItemEffects : [];
    const isWitcher = vm.page2IsWitcher === true;

    const alliesHeaders = isWitcher
      ? [tx.page2.alliesCols.gender, tx.page2.alliesCols.position, tx.page2.alliesCols.acquaintance, tx.page2.alliesCols.howClose, tx.page2.alliesCols.alive]
      : [tx.page2.alliesCols.gender, tx.page2.alliesCols.position, tx.page2.alliesCols.howMet, tx.page2.alliesCols.howClose, tx.page2.alliesCols.where];
    const alliesBaseRows = allies.map((a) =>
      isWitcher
        ? [a.gender, a.position, a.howMet, a.howClose, a.isAlive]
        : [a.gender, a.position, a.howMet, a.howClose, a.where],
    );
    const alliesRows = [...alliesBaseRows];
    for (let i = 0; i < pdfTableSettings.allies.emptyRows; i += 1) {
      alliesRows.push(new Array(alliesHeaders.length).fill(''));
    }

    const enemiesHeaders = isWitcher
      ? [tx.page2.enemiesCols.gender, tx.page2.enemiesCols.position, tx.page2.enemiesCols.power, tx.page2.enemiesCols.cause, tx.page2.enemiesCols.result, tx.page2.enemiesCols.alive]
      : [tx.page2.enemiesCols.victim, tx.page2.enemiesCols.gender, tx.page2.enemiesCols.position, tx.page2.enemiesCols.cause, tx.page2.enemiesCols.power, tx.page2.enemiesCols.level, tx.page2.enemiesCols.result];
    const enemiesBaseRows = enemies.map((e) =>
      isWitcher
        ? [e.gender, e.position, e.power, e.cause, e.result, e.alive]
        : [e.victim, e.gender, e.position, e.cause, e.power, e.level, e.result],
    );
    const enemiesRows = [...enemiesBaseRows];
    for (let i = 0; i < pdfTableSettings.enemies.emptyRows; i += 1) {
      enemiesRows.push(new Array(enemiesHeaders.length).fill(''));
    }
    const shouldRenderAllies = alliesBaseRows.length > 0 || pdfTableSettings.allies.showIfEmpty;
    const shouldRenderEnemies = enemiesBaseRows.length > 0 || pdfTableSettings.enemies.showIfEmpty;
    if (shouldRenderAllies) {
      const alliesH = this.measureDataGridCardHeight(this.w, alliesHeaders, alliesRows, isWitcher ? 4 : 2, alliesHeaders.length - 1, true);
      if (cy + alliesH > this.bottom()) {
        this.doc.addPage();
        this.paintBg();
        cy = PAGE.margin;
      }
      this.drawDataGridCard(this.x, cy, this.w, tx.page2.allies, COLORS.headerAllies, alliesHeaders, alliesRows, isWitcher ? 4 : 2, alliesHeaders.length - 1, true);
      cy += alliesH + 6;
    }

    if (shouldRenderEnemies) {
      const enemiesFlexIdx = isWitcher ? 5 : 3;
      const enemiesH = this.measureDataGridCardHeight(this.w, enemiesHeaders, enemiesRows, enemiesFlexIdx, enemiesHeaders.length - 1, true);
      if (cy + enemiesH > this.bottom()) {
        this.doc.addPage();
        this.paintBg();
        cy = PAGE.margin;
      }
      this.drawDataGridCard(this.x, cy, this.w, tx.page2.enemies, COLORS.headerEnemies, enemiesHeaders, enemiesRows, enemiesFlexIdx, enemiesHeaders.length - 1, true);
      cy += enemiesH + 6;
    }

    if (itemEffects.length > 0) {
      const effectsH = this.measureItemEffectsCardHeight(this.w, itemEffects);
      if (cy + effectsH > this.bottom()) {
        this.doc.addPage();
        this.paintBg();
        cy = PAGE.margin;
      }
      this.drawItemEffectsCard(this.x, cy, this.w, tx.page2.itemEffects, itemEffects);
      cy += effectsH + 6;
    }

    const page4Magic = vm.page4Magic as MagicPageVm | undefined;
    if (page4Magic?.onlyGiftsMagic && page4Magic.showGifts && page4Magic.giftsRows.length > 0) {
      const giftHeaders = [
        tx.page4.gifts.colName,
        tx.page4.gifts.colGroup,
        tx.page4.gifts.colSl,
        tx.page4.gifts.colVigor,
        tx.page4.gifts.colCost,
      ];
      const giftRows: MagicTableRowVm[] = page4Magic.giftsRows.map((r) => ({
        cells: [r.name, r.group, r.sl, r.vigor, r.cost],
        tooltip: r.description,
      }));
      const giftsH = this.measureMagicTableCardHeight(this.w, giftHeaders, giftRows, false);
      if (cy + giftsH <= this.bottom()) {
        this.drawMagicTableCard(
          this.x,
          cy,
          this.w,
          tx.page4.titles.gifts,
          COLORS.headerMagicGifts,
          giftHeaders,
          giftRows,
          false,
          [],
          [1, 2, 3],
          [4],
        );
        cy += giftsH + 6;
        giftsInlinedOnPage2 = true;
      }
    }

    const generalRows = Array.isArray(vm.page3GeneralGear) ? vm.page3GeneralGear : [];
    const generalHeaders = [
      tx.page3.generalGearCols.qty,
      tx.page3.generalGearCols.name,
      tx.page3.generalGearCols.concealment,
      tx.page3.generalGearCols.weight,
      tx.page3.generalGearCols.price,
    ];
    let nextGeneralGearIndex = generalGearStartIndex;
    if (generalRows.length > 0 && generalGearStartIndex < generalRows.length) {
      const minStartSpace = PAGE.headerH + 24;
      if (cy + minStartSpace > this.bottom()) {
        this.doc.addPage();
        this.paintBg();
        cy = PAGE.margin;
      }
      nextGeneralGearIndex = this.drawGeneralGearPairOnce(
        this.x,
        cy,
        this.w,
        tx.page3.generalGear,
        generalHeaders,
        generalRows,
        generalGearStartIndex,
      );
      cy = this.bottom();
    }

    const usableHeight = this.bottom() - PAGE.margin;
    const freeHeight = this.bottom() - cy;
    const freeRatio = usableHeight > 0 ? freeHeight / usableHeight : 0;
    if (freeRatio < 0.1) {
      return { nextGeneralGearIndex, giftsInlinedOnPage2 };
    }

    const offset = 40;
    const startY = cy + offset;
    const fillHeight = this.bottom() - startY;
    if (fillHeight < 50) {
      return { nextGeneralGearIndex, giftsInlinedOnPage2 };
    }

    const page3EmptyRowsLeft = Math.max(0, Math.trunc(page3FirstPairGuideRows));

    if (freeRatio > 0.4) {
      const sectionGap = 6;
      const splitHeight = Math.max(0, fillHeight - sectionGap);
      const topH = Math.floor(splitHeight / 2);
      const bottomH = splitHeight - topH;
      if (topH >= 50) {
        this.drawGeneralGearEmptyPairAt(
          this.x,
          startY,
          this.w,
          topH,
          tx.page3.generalGear,
          generalHeaders,
        );
      }
      if (bottomH >= 50) {
        this.notesStripAtCount(this.x, startY + topH + sectionGap, this.w, bottomH, tx.sections.notes, 4);
      }
      return { nextGeneralGearIndex, giftsInlinedOnPage2 };
    }

    if (page3EmptyRowsLeft < 15) {
      this.drawGeneralGearEmptyPairAt(
        this.x,
        startY,
        this.w,
        fillHeight,
        tx.page3.generalGear,
        generalHeaders,
      );
    } else {
      this.notesStripAtCount(this.x, startY, this.w, fillHeight, tx.sections.notes, 4);
    }
    return { nextGeneralGearIndex, giftsInlinedOnPage2 };
  }
  draw(vm: ReturnType<typeof buildVm>) {
    const tx = vm.tx;
    this.ensure(190);
    const freeW = this.w - PAGE.gap * 3;
    const baseW = freeW * 0.28;
    const cw = (freeW - baseW) / 3;
    const topY = this.y;
    const topH = 125;
    const x1 = this.x;
    const x2 = x1 + baseW + PAGE.gap;
    const x3 = x2 + cw + PAGE.gap;
    const x4 = x3 + cw + PAGE.gap;

    this.baseHeaderBox(
      x1,
      topY,
      baseW,
      tx.top.base,
      vm.baseRows,
      tx.labels.def,
      vm.definingSkillLine ?? '—',
      vm.definingCells ?? { skillCur: '', skillBonus: '', skillRaceBonus: '', basis: '' },
      topH,
    );
    this.topParamsCombinedBox(
      x2,
      topY,
      cw,
      tx.top.main,
      vm.mainStats,
      tx.top.extra,
      vm.extraStats,
      topH,
    );
    this.topConsumablesBox(
      x3,
      topY,
      cw,
      tx.top.cons,
      { title: tx.top.cons, columns: [tx.cols.n, tx.cols.max, tx.cols.cur], rows: vm.consRows },
      topH,
    );
    this.shell(x4, topY, cw, topH, tx.top.avatar, COLORS.headerDefault);
    this.doc.rect(x4 + 4, topY + PAGE.headerH + 4, cw - 8, topH - PAGE.headerH - 8).fill('#ddd2be');
    this.doc.lineWidth(0.4).strokeColor('#8f826b').rect(x4 + 4, topY + PAGE.headerH + 4, cw - 8, topH - PAGE.headerH - 8).stroke();
    this.fontR(7); this.doc.fillColor(COLORS.muted).text(tx.avatarPlaceholder, x4 + 8, topY + topH - 18, { width: cw - 16, align: 'center', lineBreak: false, ellipsis: true });
    this.y = topY + topH + PAGE.gap;

    const leftColumnH = this.bottom() - this.y;
    this.drawSkillSidebar(x1, this.y, baseW, leftColumnH, vm.skillSidebarGroups ?? []);
    const rightX = x2;
    const rightW = this.w - (rightX - this.x);
    const profUsedH = this.drawProfessionalBranches(rightX, this.y, rightW, vm.profBranches ?? [], tx.sections.prof);
    this.y += profUsedH + 8;
    if (vm.perksTable) {
      const perksH = this.drawPerksCompact(rightX, this.y, rightW, vm.perksTable);
      this.y += perksH + 6;
    }
    {
      const weaponsTable = vm.weaponsTable ?? {
        title: tx.sections.weapons,
        columns: [' ', tx.cols.qty, tx.sections.weapons, tx.cols.dmg, tx.cols.type, tx.cols.rel, tx.cols.hands, tx.cols.conceal, tx.cols.enh, tx.cols.wt, tx.cols.price],
        rows: [],
      };
      const weaponsH = this.drawWeaponsCompact(rightX, this.y, rightW, weaponsTable);
      this.y += weaponsH + 6;
    }
    {
      const armorTable = vm.armorTable ?? {
        title: tx.sections.armor,
        columns: [' ', tx.cols.qty, tx.sections.armor, vm.lang === 'ru' ? 'ПБ/Н' : 'SP', tx.cols.enc, vm.lang === 'ru' ? 'УБ' : 'ENH', tx.cols.wt, tx.cols.price],
        rows: [],
      };
      const dollW = Math.floor(rightW * 0.15);
      const armorGap = 6;
      const armorX = rightX + dollW + armorGap;
      const armorW = rightW - dollW - armorGap;
      const dollH = this.drawArmorDoll(rightX, this.y, dollW);
      const armorH = this.drawArmorCompact(armorX, this.y, armorW, armorTable);
      this.y += Math.max(dollH, armorH) + 6;
    }
    {
      const potionTable = vm.potionTable ?? {
        title: tx.sections.alchemy,
        columns: [tx.cols.qty, tx.cols.n, tx.cols.tox, tx.cols.time, tx.cols.effect, tx.cols.wt, tx.cols.price],
        rows: [],
      };
      const alchemyH = this.drawAlchemyCompact(rightX, this.y, rightW, potionTable);
      this.y += alchemyH + 6;
    }
    if (vm.magicTable) {
      const magicH = this.drawMagicSummaryCompact(rightX, this.y, rightW, vm.magicTable);
      this.y += magicH + 6;
    }
    {
      const notesH = this.bottom() - this.y;
      if (notesH >= 60) {
        this.notesStripAt(rightX, this.y, rightW, notesH, tx.sections.notes);
        this.y += notesH;
      }
    }
    const page3FirstPairEstimate = this.estimatePage3FirstPairGeneralGearIndex(vm);
    const page2Result = this.drawPage2(vm, page3FirstPairEstimate.nextIndex, page3FirstPairEstimate.guideRows);
    this.drawPage3Recipes(vm);
    const shouldRenderMagicPage =
      Boolean(vm.page4Magic?.shouldRender) &&
      !(vm.page4Magic?.onlyGiftsMagic && page2Result.giftsInlinedOnPage2);
    if (shouldRenderMagicPage) {
      this.drawPage4Magic(vm);
    }
    const realGeneralRows = Array.isArray(vm.page3GeneralGear) ? vm.page3GeneralGear : [];
    if (realGeneralRows.length > 0 && page2Result.nextGeneralGearIndex < realGeneralRows.length) {
      this.doc.addPage();
      this.paintBg();
      const headers = [
        tx.page3.generalGearCols.qty,
        tx.page3.generalGearCols.name,
        tx.page3.generalGearCols.concealment,
        tx.page3.generalGearCols.weight,
        tx.page3.generalGearCols.price,
      ];
      this.drawGeneralGearPairsFlow(
        PAGE.margin,
        tx.page3.generalGear,
        headers,
        realGeneralRows,
        page2Result.nextGeneralGearIndex,
      );
    }
  }
}

function createPdfBuffer(build: (doc: PDFKit.PDFDocument) => void): Promise<Buffer> {
  return new Promise<Buffer>((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 0, compress: true, info: { Title: 'WCC Character Sheet', Producer: 'WCC Cloud PDF Engine (pdfkit)' } });
    const chunks: Buffer[] = [];
    doc.on('data', (c) => chunks.push(Buffer.isBuffer(c) ? c : Buffer.from(c)));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    try { build(doc); doc.end(); } catch (e) { reject(e); }
  });
}

export async function generateCharacterPdfBuffer(params: {
  rawCharacter: Record<string, unknown>;
  resolvedCharacter: Record<string, unknown>;
  lang: Lang;
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>;
  itemEffectsGlossary?: ReadonlyArray<ItemEffectGlossaryRow>;
}): Promise<Buffer> {
  const vm = buildVmWithCatalog(
    params.resolvedCharacter,
    params.rawCharacter,
    params.lang,
    params.skillsCatalogById,
    params.itemEffectsGlossary,
  );
  return createPdfBuffer((doc) => new Painter(doc).draw(vm));
}
