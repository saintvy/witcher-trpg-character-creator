import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import type { CharacterPdfPage1Vm } from '../pages/viewModelPage1.js';
import type { CharacterPdfPage2Vm } from '../pages/viewModelPage2.js';
import type { CharacterPdfPage3Vm } from '../pages/viewModelPage3.js';
import type { CharacterPdfPage4Vm } from '../pages/viewModelPage4.js';

const assetDataUrlCache = new Map<string, string>();
const assetFormulaIngredientCache = new Map<string, string>();

const FORMULA_INGREDIENT_NAMES = [
  'Aether',
  'Caelum',
  'Fulgur',
  'Hydragenum',
  'Quebrith',
  'Rebis',
  'Sol',
  'Vermilion',
  'Vitriol',
  'Mutagen',
  'Spirits',
  'Dog Tallow',
] as const;

/** Multi-word ingredient names (formula_en is space-separated). */
const MULTI_WORD_FORMULA_INGREDIENTS = new Set<string>(['Dog Tallow']);

/** Override asset filename when it differs from English name (e.g. dog_tallow.webp for "Dog Tallow"). */
const FORMULA_INGREDIENT_FILENAME_OVERRIDE: Record<string, string> = {
  'Dog Tallow': 'dog_tallow',
};

const SHOW_GENERAL_GEAR_DESCRIPTION = true;

function assetPngDataUrl(filename: string): string {
  const cached = assetDataUrlCache.get(filename);
  if (cached) return cached;
  const primaryUrl = new URL(`../assets/body_parts/${filename}`, import.meta.url);
  let buffer: Buffer;
  try {
    buffer = readFileSync(primaryUrl);
  } catch {
    // When running compiled output from `dist/`, assets are not automatically copied.
    // Fallback to reading from `src/pdf/assets/...` relative to the current file location.
    const currentFile = fileURLToPath(import.meta.url);
    const fallbackPath = path.resolve(path.dirname(currentFile), '../../../src/pdf/assets/body_parts', filename);
    if (!existsSync(fallbackPath)) {
      throw new Error(`[pdf] missing body part asset: ${filename}`);
    }
    buffer = readFileSync(fallbackPath);
  }
  const dataUrl = `data:image/png;base64,${buffer.toString('base64')}`;
  assetDataUrlCache.set(filename, dataUrl);
  return dataUrl;
}

function assetFormulaIngredientUrl(englishName: string, alchemyStyle: 'w1' | 'w2' = 'w2'): string {
  const cacheKey = `${alchemyStyle}:${englishName}`;
  const cached = assetFormulaIngredientCache.get(cacheKey);
  if (cached) return cached;
  const filenameBase = FORMULA_INGREDIENT_FILENAME_OVERRIDE[englishName] ?? englishName;
  const filename = `${filenameBase}.webp`;
  const subdir = alchemyStyle;
  const primaryUrl = new URL(`../assets/formula_ingredients/${subdir}/${filename}`, import.meta.url);
  let buffer: Buffer;
  try {
    buffer = readFileSync(primaryUrl);
  } catch {
    const currentFile = fileURLToPath(import.meta.url);
    const fallbackPath = path.resolve(path.dirname(currentFile), '../../../src/pdf/assets/formula_ingredients', subdir, filename);
    if (!existsSync(fallbackPath)) {
      return '';
    }
    buffer = readFileSync(fallbackPath);
  }
  const dataUrl = `data:image/webp;base64,${buffer.toString('base64')}`;
  assetFormulaIngredientCache.set(cacheKey, dataUrl);
  return dataUrl;
}

function renderFormulaAsImages(formulaEn: string, alchemyStyle: 'w1' | 'w2' = 'w2'): string {
  if (!formulaEn.trim()) return '&nbsp;';
  const rawTokens = formulaEn.trim().split(/\s+/);
  const tokens: string[] = [];
  for (let i = 0; i < rawTokens.length; ) {
    const two =
      i + 1 < rawTokens.length ? `${rawTokens[i]} ${rawTokens[i + 1]}`.trim() : null;
    if (two && MULTI_WORD_FORMULA_INGREDIENTS.has(two)) {
      tokens.push(two);
      i += 2;
    } else {
      tokens.push(rawTokens[i].trim());
      i += 1;
    }
  }
  return tokens
    .map((token) => {
      const name = token;
      if (!name) return '';
      const url = assetFormulaIngredientUrl(name, alchemyStyle);
      if (!url) return escapeHtml(name);
      return `<img class="formula-ingredient-img" src="${url}" alt="${escapeHtml(name)}" />`;
    })
    .filter(Boolean)
    .join(' ');
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

/** Escapes HTML but allows <b> and </b> tags for bold formatting. */
function escapeHtmlAllowBold(value: string): string {
  const escaped = escapeHtml(value);
  return escaped.replace(/&lt;b&gt;/g, '<b>').replace(/&lt;\/b&gt;/g, '</b>');
}

/** Escapes HTML but allows <b>, </b>, <i>, </i> tags for formatting. */
function escapeHtmlAllowBoldItalic(value: string): string {
  const escaped = escapeHtml(value);
  return escaped.replace(/&lt;(\/?)(b|i)&gt;/gi, (_m, slash: string, tag: string) => `<${slash}${tag.toLowerCase()}>`);
}

function formatSigned(value: number): string {
  return value >= 0 ? `+${value}` : `${value}`;
}

function renderBonus(bonus: number | null, raceBonus: number | null): string {
  const parts: string[] = [];
  if (bonus !== null && bonus !== 0) parts.push(escapeHtml(formatSigned(bonus)));
  if (raceBonus !== null && raceBonus !== 0) parts.push(`<b>${escapeHtml(formatSigned(raceBonus))}</b>`);
  return parts.join('');
}

function renderStatValue(cur: number | null, bonus: number | null, raceBonus: number | null): string {
  const c = cur === null ? '' : String(cur);
  const b = renderBonus(bonus, raceBonus);
  if (!c && !b) return '';
  if (c && b) return `${escapeHtml(c)}${b}`;
  return c ? escapeHtml(c) : b;
}

function renderStatValueWithCappedTotal(cur: number | null, bonus: number | null, raceBonus: number | null): string {
  const base = renderStatValue(cur, bonus, raceBonus);
  if (!base) return '';
  const b = bonus ?? 0;
  const r = raceBonus ?? 0;
  const hasAnyBonus = b !== 0 || r !== 0;
  if (!hasAnyBonus) return base;
  const c = cur ?? 0;
  const total = Math.min(c + b, 10) + r;
  return `${base} = ${escapeHtml(String(total))}`;
}

function box(title: string, body: string, extraClass = ''): string {
  return `
    <section class="box ${extraClass}">
      ${title ? `<div class="box-title">${escapeHtml(title)}</div>` : ''}
      <div class="box-body">${body}</div>
    </section>
  `;
}

function boxRawTitle(titleHtml: string, body: string, extraClass = ''): string {
  return `
    <section class="box ${extraClass}">
      ${titleHtml ? `<div class="box-title">${titleHtml}</div>` : ''}
      <div class="box-body">${body}</div>
    </section>
  `;
}

function renderBaseInfo(vm: CharacterPdfPage1Vm): string {
  const schoolLabel = vm.i18n.lang.toLowerCase().startsWith('ru') ? 'Школа' : 'School';
  const rows: Array<[string, string]> = [
    [vm.i18n.base.name, vm.base.name],
    [vm.i18n.base.race, vm.base.race],
    [vm.i18n.base.gender, vm.base.gender],
    [vm.i18n.base.age, vm.base.age],
    [vm.i18n.base.profession, vm.base.profession],
    ...(vm.base.school ? ([[schoolLabel, vm.base.school]] as Array<[string, string]>) : []),
    [vm.i18n.base.definingSkill, vm.base.definingSkill],
  ];

  return `
    <table class="kv">
      <tbody>
        ${rows
          .map(
            ([k, v]) => `
              <tr>
                <td class="kv-k">${escapeHtml(k)}</td>
                <td class="kv-v">${escapeHtml(v || '')}</td>
              </tr>
            `,
          )
          .join('')}
      </tbody>
    </table>
  `;
}

function renderMainStats(vm: CharacterPdfPage1Vm): string {
  const pairs = vm.mainStats;
  const rows = [];
  for (let i = 0; i < pairs.length; i += 2) {
    const left = pairs[i];
    const right = pairs[i + 1];
    rows.push(`
      <tr>
        <td class="ms-k">${left ? escapeHtml(left.label) : ''}</td>
        <td class="ms-v">${left ? renderStatValue(left.cur, left.bonus, left.raceBonus) : ''}</td>
        <td class="ms-k">${right ? escapeHtml(right.label) : ''}</td>
        <td class="ms-v">${right ? renderStatValue(right.cur, right.bonus, right.raceBonus) : ''}</td>
      </tr>
    `);
  }
  return `<table class="main-stats"><tbody>${rows.join('')}</tbody></table>`;
}

function renderParamsCombined(vm: CharacterPdfPage1Vm): string {
  const mainPairs = vm.mainStats;
  const mainRows: string[] = [];
  for (let i = 0; i < mainPairs.length; i += 2) {
    const left = mainPairs[i];
    const right = mainPairs[i + 1];
    mainRows.push(`
      <tr>
        <td class="ms-k">${left ? escapeHtml(left.label) : ''}</td>
        <td class="ms-v">${left ? renderStatValue(left.cur, left.bonus, left.raceBonus) : ''}</td>
        <td class="ms-k">${right ? escapeHtml(right.label) : ''}</td>
        <td class="ms-v">${right ? renderStatValue(right.cur, right.bonus, right.raceBonus) : ''}</td>
      </tr>
    `);
  }

  const additionalItems: Array<[string, string]> = [
    [vm.i18n.derived.run, vm.computed.run],
    [vm.i18n.derived.leap, vm.computed.leap],
    [vm.i18n.derived.stability, vm.computed.stability],
    [vm.i18n.derived.rest, vm.computed.rest],
    [vm.i18n.derived.punch, vm.computed.punch],
    [vm.i18n.derived.kick, vm.computed.kick],
    [vm.i18n.derived.vigor, vm.computed.vigor],
  ];
  const cells = additionalItems.concat(new Array(Math.max(0, 8 - additionalItems.length)).fill(['', '']));
  const additionalRow = (start: number) => `
    <tr>
      <td class="comp-k">${escapeHtml(cells[start][0] || '')}</td>
      <td class="comp-v">${escapeHtml(cells[start][1] || '')}</td>
      <td class="comp-k">${escapeHtml(cells[start + 1][0] || '')}</td>
      <td class="comp-v">${escapeHtml(cells[start + 1][1] || '')}</td>
    </tr>
  `;

  return `
    <table class="params-table">
      <tbody>
        <tr><td class="subhead" colspan="4">${escapeHtml(vm.i18n.section.mainParams)}</td></tr>
        ${mainRows.join('')}
        <tr><td class="subhead" colspan="4">${escapeHtml(vm.i18n.section.extraParams)}</td></tr>
        ${additionalRow(0)}
        ${additionalRow(2)}
        ${additionalRow(4)}
        ${additionalRow(6)}
      </tbody>
    </table>
  `;
}

function renderConsumables(vm: CharacterPdfPage1Vm): string {
  return `
    <table class="consumables">
      <thead>
        <tr>
          <th>${escapeHtml(vm.i18n.consumables.colParameter)}</th>
          <th class="narrow">${escapeHtml(vm.i18n.consumables.colMax)}</th>
          <th class="narrow">${escapeHtml(vm.i18n.consumables.colCur)}</th>
        </tr>
      </thead>
      <tbody>
        ${vm.consumables
          .map(
            (c) => `
              <tr>
                <td>${escapeHtml(c.label)}</td>
                <td class="narrow t-right">${escapeHtml(c.max || '')}</td>
                <td class="narrow t-right">${escapeHtml(c.current || '')}</td>
              </tr>
            `,
          )
          .join('')}
      </tbody>
    </table>
  `;
}

function renderAvatar(vm: CharacterPdfPage1Vm): string {
  if (vm.avatar.dataUrl) {
    return `<img class="avatar-img" src="${escapeHtml(vm.avatar.dataUrl)}" alt="avatar" />`;
  }
  return `<div class="avatar-placeholder">${escapeHtml(vm.i18n.avatarPlaceholder)}</div>`;
}

function renderSkillGroups(vm: CharacterPdfPage1Vm): string {
  return vm.skillGroups
    .map((group) => {
      const statValue = renderStatValueWithCappedTotal(group.stat.cur, group.stat.bonus, group.stat.raceBonus);
      const skillsHtml = group.skills
        .map((s) => {
          const cur = s.cur !== null && s.cur !== 0 ? String(s.cur) : '';
          const bonus = renderBonus(s.bonus, s.raceBonus);
          const statCur = group.stat.cur ?? 0;
          const statBonus = group.stat.bonus ?? 0;
          const statRaceBonus = group.stat.raceBonus ?? 0;
          const skillCur = s.cur ?? 0;
          const skillBonus = s.bonus ?? 0;
          const raceBonus = s.raceBonus ?? 0;
          const baseValue =
            Math.min(statCur + statBonus, 10) + statRaceBonus + Math.min(skillCur + skillBonus, 10) + raceBonus;
          const shouldShowBase =
            (s.cur !== null && s.cur !== 0) || (s.bonus !== null && s.bonus !== 0) || (s.raceBonus !== null && s.raceBonus !== 0);
          const base = shouldShowBase ? escapeHtml(String(baseValue)) : '';
          return `
            <tr>
              <td class="sk-name">${escapeHtml(s.name)}</td>
              <td class="sk-cur">${escapeHtml(cur)}</td>
              <td class="sk-bonus">${bonus}</td>
              <td class="sk-base">${base}</td>
            </tr>
          `;
        })
        .join('');

      return `
        <section class="skill-group">
          <div class="skill-group-header">
            <div class="sg-title">${escapeHtml(group.statLabel)}</div>
            <div class="sg-stat">${statValue}</div>
          </div>
          <table class="skills">
            <tbody>
              ${skillsHtml}
            </tbody>
          </table>
        </section>
      `;
    })
    .join('');
}

function renderProfessional(vm: CharacterPdfPage1Vm): string {
  const colorClass: Record<CharacterPdfPage1Vm['professional']['branches'][number]['color'], string> = {
    blue: 'prof-col-blue',
    green: 'prof-col-green',
    red: 'prof-col-red',
  };

  return `
    <div class="prof-grid">
      ${vm.professional.branches
        .map((b) => {
          const rows = new Array(3).fill(null).map((_, i) => b.skills[i] ?? null);
          return `
            <table class="prof-table ${colorClass[b.color]}">
              <colgroup>
                <col style="width:80%" />
                <col style="width:20%" />
              </colgroup>
              <thead>
                <tr><th colspan="2">${escapeHtml(b.title)}</th></tr>
              </thead>
              <tbody>
                ${rows
                  .map((row) => {
                    const name = row ? row.name : '';
                    const param = row?.paramAbbr ? ` (${row.paramAbbr})` : '';
                    return `<tr><td class="prof-skill">${escapeHtml(name)}<span class="prof-param">${escapeHtml(
                      param,
                    )}</span></td><td class="prof-val"></td></tr>`;
                  })
                  .join('')}
              </tbody>
            </table>
          `;
        })
        .join('')}
    </div>
  `;
}

function renderPerksTable(vm: CharacterPdfPage1Vm): string {
  if (!vm.perks.length) return '';
  const rows = vm.perks
    .map(
      (p) => `
      <tr>
        <td class="equip-fit equip-left">${escapeHtmlAllowBold(p.perk)}</td>
        <td class="equip-effect">${escapeHtml(p.effect)}</td>
      </tr>
    `,
    )
    .join('');
  return `
    <div class="perks-box">
      <table class="perks-table">
        <colgroup>
          <col class="equip-fit" />
          <col />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.perks.colPerk)}</th>
            <th>${escapeHtml(vm.i18n.tables.perks.colEffect)}</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
  `;
}

function renderEquipment(vm: CharacterPdfPage1Vm): string {
  const weaponRowsWanted = Math.max(vm.equipment.weapons.length + 3, 3);
  // Calculate armor rows: each filled row = 1 point (2 if has effects), empty rows = max(7 - X, 3)
  const armorPoints = vm.equipment.armors.reduce((sum, armor) => {
    return sum + (armor.effects ? 2 : 1);
  }, 0);
  const armorEmptyRows = Math.max(7 - armorPoints, 3);
  const armorRowsWanted = vm.equipment.armors.length + armorEmptyRows;
  const potionRowsWanted = Math.max(vm.equipment.potions.length + 3, 3);
  const magicRowsWanted = Math.max(vm.equipment.magic.length + 3, 3);

  const weaponRows = new Array(weaponRowsWanted).fill(null).map((_, i) => vm.equipment.weapons[i] ?? null);
  const armorRows = new Array(armorRowsWanted).fill(null).map((_, i) => vm.equipment.armors[i] ?? null);
  const potionRows = new Array(potionRowsWanted).fill(null).map((_, i) => vm.equipment.potions[i] ?? null);
  const magicRows = new Array(magicRowsWanted).fill(null).map((_, i) => vm.equipment.magic[i] ?? null);

  return `
    <div class="equip-area">
      <table class="equip-table equip-weapons">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.weapons.colCheck)}</th>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.weapons.colQty)}</th>
            <th>${escapeHtml(vm.i18n.tables.weapons.title)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colDmg)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colType)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colReliability)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colHands)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colConcealment)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colEnh)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colWeight)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.weapons.colPrice)}</th>
          </tr>
        </thead>
        <tbody>
          ${weaponRows
            .map((w) => {
              if (!w) {
                return `
                  <tr>
                    <td class="equip-fit equip-right">&nbsp;</td>
                    <td class="equip-fit equip-right">&nbsp;</td>
                    <td class="weapon-name">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                  </tr>
                `;
              }
              const effects = w.effects ? `<div class="weapon-effects"><i>${escapeHtml(w.effects)}</i></div>` : '';
              return `
                <tr>
                  <td class="equip-fit equip-right"></td>
                  <td class="equip-fit equip-right">${escapeHtml(w.qty || '')}</td>
                  <td class="weapon-name">
                    <div class="weapon-title">${escapeHtml(w.name || '')}</div>
                    ${effects}
                  </td>
                  <td class="equip-fit equip-left">${escapeHtml(w.dmg || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(w.dmgTypes || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(w.reliability || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(w.hands || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(w.concealment || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(w.enhancements || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(w.weight || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(w.price || '')}</td>
                </tr>
              `;
            })
            .join('')}
        </tbody>
      </table>

      <div class="equip-row">
        <div class="equip-row-left">
          <table class="equip-table equip-bricks">
            <colgroup>
              <col />
              <col />
              <col />
              <col />
            </colgroup>
            <tbody>
              <tr>
                <td class="brick-empty"></td>
                <td class="brick-cell" colspan="2">
                  <div class="brick-inner">
                    <img class="brick-img" src="${assetPngDataUrl('head.png')}" alt="" />
                    <div class="brick-spacer"></div>
                  </div>
                </td>
                <td class="brick-empty"></td>
              </tr>
              <tr>
                <td class="brick-cell" colspan="2">
                  <div class="brick-inner">
                    <img class="brick-img" src="${assetPngDataUrl('hand_left.png')}" alt="" />
                    <div class="brick-spacer"></div>
                  </div>
                </td>
                <td class="brick-cell" colspan="2">
                  <div class="brick-inner">
                    <img class="brick-img" src="${assetPngDataUrl('hand_right.png')}" alt="" />
                    <div class="brick-spacer"></div>
                  </div>
                </td>
              </tr>
              <tr>
                <td class="brick-empty"></td>
                <td class="brick-cell" colspan="2">
                  <div class="brick-inner">
                    <img class="brick-img" src="${assetPngDataUrl('chest.png')}" alt="" />
                    <div class="brick-spacer"></div>
                  </div>
                </td>
                <td class="brick-empty"></td>
              </tr>
              <tr>
                <td class="brick-cell" colspan="2">
                  <div class="brick-inner">
                    <img class="brick-img" src="${assetPngDataUrl('leg_left.png')}" alt="" />
                    <div class="brick-spacer"></div>
                  </div>
                </td>
                <td class="brick-cell" colspan="2">
                  <div class="brick-inner">
                    <img class="brick-img" src="${assetPngDataUrl('leg_right.png')}" alt="" />
                    <div class="brick-spacer"></div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="equip-row-right">
          <table class="equip-table equip-armors">
            <colgroup>
              <col class="equip-fit" />
              <col class="equip-fit" />
              <col />
              <col class="equip-fit" />
              <col class="equip-fit" />
              <col class="equip-fit" />
              <col class="equip-fit" />
              <col class="equip-fit" />
            </colgroup>
            <thead>
              <tr>
                <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.armors.colCheck)}</th>
                <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.armors.colQty)}</th>
                <th>${escapeHtml(vm.i18n.tables.armors.title)}</th>
                <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.armors.colSp)}</th>
                <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.armors.colEnc)}</th>
                <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.armors.colEnh)}</th>
                <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.armors.colWeight)}</th>
                <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.armors.colPrice)}</th>
              </tr>
            </thead>
            <tbody>
              ${armorRows
                .map((a) => {
                  if (!a) {
                    return `
                      <tr>
                        <td class="equip-fit equip-right">&nbsp;</td>
                        <td class="equip-fit equip-right">&nbsp;</td>
                        <td class="armor-name">&nbsp;</td>
                        <td class="equip-fit equip-left">&nbsp;</td>
                        <td class="equip-fit equip-left">&nbsp;</td>
                        <td class="equip-fit equip-left">&nbsp;</td>
                        <td class="equip-fit equip-left">&nbsp;</td>
                        <td class="equip-fit equip-left">&nbsp;</td>
                      </tr>
                    `;
                  }
                  const effects = a.effects ? `<div class="armor-effects"><i>${escapeHtml(a.effects)}</i></div>` : '';
                  return `
                    <tr>
                      <td class="equip-fit equip-right"></td>
                      <td class="equip-fit equip-right">${escapeHtml(a.qty || '')}</td>
                      <td class="armor-name">
                        <div class="armor-title">${escapeHtml(a.name || '')}</div>
                        ${effects}
                      </td>
                      <td class="equip-fit equip-left">${escapeHtml(a.sp || '')}</td>
                      <td class="equip-fit equip-left">${escapeHtml(a.enc || '')}</td>
                      <td class="equip-fit equip-left">${escapeHtml(a.enhancements || '')}</td>
                      <td class="equip-fit equip-left">${escapeHtml(a.weight || '')}</td>
                      <td class="equip-fit equip-left">${escapeHtml(a.price || '')}</td>
                    </tr>
                  `;
                })
                .join('')}
            </tbody>
          </table>
        </div>
      </div>

      <table class="equip-table equip-potions">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.potions.colQty)}</th>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.potions.title)}</th>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.potions.colTox)}</th>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.potions.colTime)}</th>
            <th>${escapeHtml(vm.i18n.tables.potions.colEffect)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.potions.colWeight)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.potions.colPrice)}</th>
          </tr>
        </thead>
        <tbody>
          ${potionRows
            .map((p) => {
              if (!p) {
                return `
                  <tr>
                    <td class="equip-fit equip-right">&nbsp;</td>
                    <td class="equip-fit equip-right">&nbsp;</td>
                    <td class="equip-fit equip-right">&nbsp;</td>
                    <td class="equip-fit equip-right">&nbsp;</td>
                    <td>&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                  </tr>
                `;
              }
              return `
                <tr>
                  <td class="equip-fit equip-right">${escapeHtml(p.qty || '')}</td>
                  <td class="equip-fit equip-right">${escapeHtml(p.name || '')}</td>
                  <td class="equip-fit equip-right">${escapeHtml(p.toxicity || '')}</td>
                  <td class="equip-fit equip-right">${escapeHtml(p.duration || '')}</td>
                  <td class="equip-effect">${escapeHtml(p.effect || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(p.weight || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(p.price || '')}</td>
                </tr>
              `;
            })
            .join('')}
        </tbody>
      </table>

      ${vm.equipment.magic.length > 0 ? `
      <table class="equip-table equip-magic">
        <colgroup>
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.magic.colType)}</th>
            <th>${escapeHtml(vm.i18n.tables.magic.colName)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colElement)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colVigor)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colVigorKeep)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colDamage)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colTime)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colDistance)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colSize)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.magic.colForm)}</th>
          </tr>
        </thead>
        <tbody>
          ${magicRows
            .map((m) => {
              if (!m) {
                return `
                  <tr>
                    <td class="equip-fit equip-right">&nbsp;</td>
                    <td>&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                    <td class="equip-fit equip-left">&nbsp;</td>
                  </tr>
                `;
              }
              return `
                <tr>
                  <td class="equip-fit equip-right">${escapeHtml(m.type || '')}</td>
                  <td>${escapeHtml(m.name || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.element || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.staminaCast || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.staminaKeeping || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.damage || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.effectTime || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.distance || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.zoneSize || '')}</td>
                  <td class="equip-fit equip-left">${escapeHtml(m.form || '')}</td>
                </tr>
              `;
            })
            .join('')}
        </tbody>
      </table>
      ` : ''}

      ${renderNotes(vm.i18n.tables.notes.title)}
    </div>
  `;
}

function renderNotes(title: string): string {
  return `
    <div class="notes-wrapper" id="notes-wrapper" style="height:0; overflow:hidden;">
      <div class="notes-grid">
        ${new Array(3)
          .fill(null)
          .map(
            () => `
              <table class="notes-table">
                <thead><tr><th>${escapeHtml(title)}</th></tr></thead>
                <tbody></tbody>
              </table>
            `,
          )
          .join('')}
      </div>
    </div>
  `;
}

function renderPage1(vm: CharacterPdfPage1Vm): string {
  return `
    <div class="page page1">
      <div class="grid-top">
        <div class="pos-base">${box(vm.i18n.section.baseData, renderBaseInfo(vm))}</div>
        <div class="pos-main">${box('', renderParamsCombined(vm))}</div>
        <div class="pos-consumables">${box(vm.i18n.section.consumables, renderConsumables(vm))}</div>
        <div class="pos-avatar">${box(vm.i18n.section.avatar, renderAvatar(vm), 'avatar-box')}</div>
      </div>

      <div class="grid-bottom">
        <div class="skills-column">
          ${renderSkillGroups(vm)}
        </div>
        <div class="prof-title-row">${escapeHtml(vm.i18n.section.professional)}</div>
        <div class="prof-area">
          ${renderProfessional(vm)}
          ${renderPerksTable(vm)}
          ${renderEquipment(vm)}
        </div>
      </div>
    </div>
  `;
}

function renderLoreBlock(vm: CharacterPdfPage2Vm): string {
  const body = vm.loreBlocks.length
    ? `<div class="lore-paras">${vm.loreBlocks.map((b) => b.html).join('')}</div>`
    : `<div class="muted">&nbsp;</div>`;
  return box(vm.i18n.section.lore, body, 'lore-box');
}

function renderSocialStatusTable(vm: CharacterPdfPage2Vm): string {
  const { groups, reputation } = vm.socialStatusTable;
  const titleText = vm.i18n.section.socialStatus;
  const repLabel = vm.i18n.tables.socialStatus.reputationLabel;
  const titleHtml = `${escapeHtml(titleText)} - (${escapeHtml(repLabel)} <span class="reputation-muted">${escapeHtml(String(reputation))}</span> )`;
  const headerCells = groups
    .map((g) => `<th class="equip-fit equip-left">${escapeHtml(g.groupName)}</th>`)
    .join('');
  const valueCells = groups
    .map((g) => {
      const and = vm.i18n.tables.socialStatus.and;
      const statusFeared = vm.i18n.tables.socialStatus.statusFeared;
      const valHtml = g.isFeared
        ? `${escapeHtml(g.statusLabel)}<br>${escapeHtml(and)}${escapeHtml(statusFeared)}`
        : escapeHtml(g.statusLabel);
      return `<td class="equip-fit equip-left social-status-cell">${valHtml}</td>`;
    })
    .join('');
  const colgroup = groups.map(() => '<col class="equip-fit" />').join('');
  const body =
    groups.length > 0
      ? `
      <table class="equip-table equip-social-status">
        <colgroup>${colgroup}</colgroup>
        <thead><tr>${headerCells}</tr></thead>
        <tbody><tr>${valueCells}</tr></tbody>
      </table>
    `
      : '<div class="muted">&nbsp;</div>';
  return boxRawTitle(titleHtml, body, 'social-status-box');
}

function renderLifeEvents(vm: CharacterPdfPage2Vm): string {
  const rows = vm.lifeEvents.length
    ? vm.lifeEvents
        .map(
          (e) => `
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(e.period)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.type)}</td>
            <td class="equip-effect">${escapeHtml(e.description)}</td>
          </tr>
        `,
        )
        .join('')
    : `
        <tr>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-effect">&nbsp;</td>
        </tr>
      `;

  return box(
    vm.i18n.section.lifePath,
    `
      <table class="equip-table equip-life-events">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.lifeEvents.colPeriod)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.lifeEvents.colType)}</th>
            <th>${escapeHtml(vm.i18n.tables.lifeEvents.colDesc)}</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `,
    'life-box',
  );
}

function renderStyleTable(vm: CharacterPdfPage2Vm): string {
  const s = vm.styleTable;
  return box(
    vm.i18n.section.style,
    `
      <table class="equip-table equip-style">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.style.colClothing)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.style.colPersonality)}</th>
            <th>${escapeHtml(vm.i18n.tables.style.colHairStyle)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.style.colAffectations)}</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(s.clothing)}</td>
            <td class="equip-fit equip-left">${escapeHtml(s.personality)}</td>
            <td class="equip-effect">${escapeHtml(s.hairStyle)}</td>
            <td class="equip-fit equip-left">${escapeHtml(s.affectations)}</td>
          </tr>
        </tbody>
      </table>
    `,
    'style-box',
  );
}

function renderValuesTable(vm: CharacterPdfPage2Vm): string {
  const v = vm.valuesTable;
  return box(
    vm.i18n.section.values,
    `
      <table class="equip-table equip-values">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.values.colValuedPerson)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.values.colValue)}</th>
            <th>${escapeHtml(vm.i18n.tables.values.colFeelingsOnPeople)}</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(v.valuedPerson)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.value)}</td>
            <td class="equip-effect">${escapeHtml(v.feelingsOnPeople)}</td>
          </tr>
        </tbody>
      </table>
    `,
    'values-box',
  );
}

function renderSiblings(vm: CharacterPdfPage2Vm): string {
  const rows = vm.siblings.length
    ? vm.siblings
        .map(
          (s) => `
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(s.age)}</td>
            <td class="equip-fit equip-left">${escapeHtml(s.gender)}</td>
            <td class="equip-effect">${escapeHtml(s.attitude)}</td>
            <td class="equip-fit equip-left">${escapeHtml(s.personality)}</td>
          </tr>
        `,
        )
        .join('')
    : `
        <tr>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-effect">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
        </tr>
      `;

  return box(
    vm.i18n.section.siblings,
    `
      <table class="equip-table equip-siblings">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.siblings.colAge)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.siblings.colGender)}</th>
            <th>${escapeHtml(vm.i18n.tables.siblings.colAttitude)}</th>
            <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.siblings.colPersonality)}</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `,
    'siblings-box',
  );
}

function renderAllies(vm: CharacterPdfPage2Vm): string {
  const isWitcher = vm.alliesIsWitcher;

  const headerRow = isWitcher
    ? `
        <tr>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colGender)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colPosition)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colAcquaintance)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colHowClose)}</th>
          <th>${escapeHtml(vm.i18n.tables.allies.colAlive)}</th>
        </tr>
      `
    : `
        <tr>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colGender)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colPosition)}</th>
          <th>${escapeHtml(vm.i18n.tables.allies.colHowMet)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colHowClose)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.allies.colWhere)}</th>
        </tr>
      `;

  const colgroup = isWitcher
    ? `
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
        </colgroup>
      `
    : `
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
      `;

  const rows = vm.allies.length
    ? vm.allies
        .map((a) => {
          if (isWitcher) {
            return `
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(a.gender)}</td>
            <td class="equip-fit equip-left">${escapeHtml(a.position)}</td>
            <td class="equip-fit equip-left">${escapeHtml(a.howMet)}</td>
            <td class="equip-fit equip-left">${escapeHtml(a.howClose)}</td>
            <td class="equip-effect">${escapeHtml(a.isAlive)}</td>
          </tr>
        `;
          }
          return `
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(a.gender)}</td>
            <td class="equip-fit equip-left">${escapeHtml(a.position)}</td>
            <td class="equip-effect">${escapeHtml(a.howMet)}</td>
            <td class="equip-fit equip-left">${escapeHtml(a.howClose)}</td>
            <td class="equip-fit equip-left">${escapeHtml(a.where)}</td>
          </tr>
        `;
        })
        .join('')
    : isWitcher
      ? `
        <tr>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-effect">&nbsp;</td>
        </tr>
      `
      : `
        <tr>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-effect">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
        </tr>
      `;

  const emptyRowAllies = isWitcher
    ? `<tr><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-effect">&nbsp;</td></tr>`
    : `<tr><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-effect">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td></tr>`;

  return box(
    vm.i18n.section.allies,
    `
      <table class="equip-table equip-allies">
        ${colgroup}
        <thead>${headerRow}</thead>
        <tbody>${rows}${emptyRowAllies}</tbody>
      </table>
    `,
    'allies-box',
  );
}

function renderEnemies(vm: CharacterPdfPage2Vm): string {
  const isWitcher = vm.enemiesIsWitcher;

  const headerRow = isWitcher
    ? `
        <tr>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colGender)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colPosition)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colPower)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colCause)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colResult)}</th>
          <th>${escapeHtml(vm.i18n.tables.enemies.colAlive)}</th>
        </tr>
      `
    : `
        <tr>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colVictim)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colGender)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colPosition)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colCause)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colPower)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colLevel)}</th>
          <th class="equip-fit equip-left">${escapeHtml(vm.i18n.tables.enemies.colResult)}</th>
        </tr>
      `;

  const colgroup = isWitcher
    ? `
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
        </colgroup>
      `
    : `
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
      `;

  const rows = vm.enemies.length
    ? vm.enemies
        .map((e) => {
          if (isWitcher) {
            return `
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(e.gender)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.position)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.power)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.cause)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.result)}</td>
            <td class="equip-effect">${escapeHtml(e.alive)}</td>
          </tr>
        `;
          }
          return `
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(e.victim)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.gender)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.position)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.cause)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.power)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.level)}</td>
            <td class="equip-fit equip-left">${escapeHtml(e.result)}</td>
          </tr>
        `;
        })
        .join('')
    : isWitcher
      ? `
        <tr>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-effect">&nbsp;</td>
        </tr>
      `
      : `
        <tr>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
        </tr>
      `;

  const emptyRowEnemies = isWitcher
    ? `<tr><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-effect">&nbsp;</td></tr>`
    : `<tr><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td><td class="equip-fit equip-left">&nbsp;</td></tr>`;

  return box(
    vm.i18n.section.enemies,
    `
      <table class="equip-table equip-enemies">
        ${colgroup}
        <thead>${headerRow}</thead>
        <tbody>${rows}${emptyRowEnemies}</tbody>
      </table>
    `,
    'enemies-box',
  );
}

/** Escapes HTML but allows <br> and <br/> in string (for header line breaks). */
function escapeHtmlAllowBr(value: string): string {
  const escaped = escapeHtml(value);
  return escaped.replace(/&lt;br\s*\/?&gt;/gi, '<br>');
}

function renderVehiclesTable(vm: CharacterPdfPage3Vm): string {
  const showOccupancy = vm.vehicles.some((v) => v.occupancy.trim() !== '');
  const t = vm.i18n.tables.vehicles;
  const headerCells = [
    `<th class="equip-fit equip-right">${escapeHtml(t.colQty)}</th>`,
    `<th class="equip-fit equip-left">${escapeHtml(t.colType)}</th>`,
    `<th>${escapeHtml(t.colVehicle)}</th>`,
    `<th class="equip-fit equip-left">${escapeHtml(t.colSkill)}</th>`,
    `<th class="equip-fit equip-left">${escapeHtml(t.colMod)}</th>`,
    `<th class="equip-fit equip-left">${escapeHtml(t.colSpeed)}</th>`,
    `<th class="equip-fit equip-left">${escapeHtml(t.colHp)}</th>`,
    `<th class="equip-fit equip-left">${escapeHtml(t.colWeight)}</th>`,
    `<th class="equip-fit equip-left">${escapeHtml(t.colPrice)}</th>`,
  ];
  if (showOccupancy) headerCells.push(`<th class="equip-fit equip-left">${escapeHtml(t.colOccupancy)}</th>`);
  const emptyRowCells = [
    '<td class="equip-fit equip-right">&nbsp;</td>',
    '<td class="equip-fit equip-left">&nbsp;</td>',
    '<td>&nbsp;</td>',
    '<td class="equip-fit equip-left">&nbsp;</td>',
    '<td class="equip-fit equip-left">&nbsp;</td>',
    '<td class="equip-fit equip-left">&nbsp;</td>',
    '<td class="equip-fit equip-left">&nbsp;</td>',
    '<td class="equip-fit equip-left">&nbsp;</td>',
    '<td class="equip-fit equip-left">&nbsp;</td>',
  ];
  if (showOccupancy) emptyRowCells.push('<td class="equip-fit equip-left">&nbsp;</td>');
  const emptyRow = `<tr>${emptyRowCells.join('')}</tr>`;
  const rows =
    vm.vehicles.length > 0
      ? vm.vehicles
          .map((v) => {
            const occCell = showOccupancy ? `<td class="equip-fit equip-left">${escapeHtml(v.occupancy)}</td>` : '';
            return `
          <tr>
            <td class="equip-fit equip-right">${escapeHtml(v.amount)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.subgroupName)}</td>
            <td class="equip-vehicle-name">${escapeHtml(v.vehicleName)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.base)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.controlModifier)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.speed)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.hp)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.weight)}</td>
            <td class="equip-fit equip-left">${escapeHtml(v.price)}</td>
            ${occCell}
          </tr>
        `;
          })
          .join('')
      : emptyRow;
  const colgroup = [
    '<col class="equip-fit" />',
    '<col class="equip-fit" />',
    '<col />',
    '<col class="equip-fit" />',
    '<col class="equip-fit" />',
    '<col class="equip-fit" />',
    '<col class="equip-fit" />',
    '<col class="equip-fit" />',
    '<col class="equip-fit" />',
  ];
  if (showOccupancy) colgroup.push('<col class="equip-fit" />');
  return box(
    vm.i18n.section.vehicles,
    `
      <table class="equip-table equip-vehicles">
        <colgroup>${colgroup.join('')}</colgroup>
        <thead><tr>${headerCells.join('')}</tr></thead>
        <tbody>${rows}</tbody>
      </table>
    `,
    'vehicles-box',
  );
}

function renderRecipesTable(vm: CharacterPdfPage3Vm, alchemyStyle: 'w1' | 'w2' = 'w2'): string {
  const t = vm.i18n.tables.recipes;
  const leg = vm.i18n.formulaLegend;
  const headerRow = `
    <tr>
      <th class="equip-fit equip-right">${escapeHtmlAllowBr(t.colQty)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colRecipeGroup)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colRecipeName)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colComplexity)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colTimeCraft)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colFormula)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colPriceFormula)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colMinimalIngredientsCost)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colTimeEffect)}</th>
      <th class="equip-fit equip-left recipes-cell-toxicity">${escapeHtmlAllowBr(t.colToxicity)}</th>
      <th>${escapeHtmlAllowBr(t.colRecipeDescription)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colWeightPotion)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colPricePotion)}</th>
    </tr>
  `;
  const emptyRecipeRow = `
        <tr>
          <td class="equip-fit equip-right">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left formula-cell">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left recipes-cell-toxicity">&nbsp;</td>
          <td class="equip-effect">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
          <td class="equip-fit equip-left">&nbsp;</td>
        </tr>
      `;
  const dataRows =
    vm.recipes.length > 0
      ? vm.recipes
          .map((r) => `
          <tr>
            <td class="equip-fit equip-right">${escapeHtml(r.amount)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.recipeGroup)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.recipeName)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.complexity)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.timeCraft)}</td>
            <td class="equip-fit equip-left formula-cell">${renderFormulaAsImages(r.formulaEn, alchemyStyle)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.priceFormula)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.minimalIngredientsCost)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.timeEffect)}</td>
            <td class="equip-fit equip-left recipes-cell-toxicity">${escapeHtml(r.toxicity)}</td>
            <td class="equip-effect">${escapeHtml(r.recipeDescription)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.weightPotion)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.pricePotion)}</td>
          </tr>
        `)
          .join('')
      : '';
  const rows = dataRows + emptyRecipeRow + emptyRecipeRow + emptyRecipeRow;
  const legendPairs = FORMULA_INGREDIENT_NAMES.map((name) => {
    const url = assetFormulaIngredientUrl(name, alchemyStyle);
    const label = escapeHtml((leg as Record<string, string>)[name] ?? name);
    if (!url) return label;
    return `<img class="formula-legend-img" src="${url}" alt="${escapeHtml(name)}" /> - ${label}`;
  }).join(', ');
  const legendRow = `
    <tr class="recipes-legend-row">
      <td colspan="13" class="recipes-legend-cell">${legendPairs}</td>
    </tr>
  `;
  return box(
    vm.i18n.section.recipes,
    `
      <table class="equip-table equip-recipes">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
        <thead>${headerRow}</thead>
        <tbody>${rows}${legendRow}</tbody>
      </table>
    `,
    'recipes-box',
  );
}

function renderBlueprintsTable(vm: CharacterPdfPage3Vm): string {
  const t = vm.i18n.tables.blueprints;
  const headerRow = `
    <tr>
      <th class="equip-fit equip-right">${escapeHtmlAllowBr(t.colQty)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colName)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colCraftLevel)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colDifficultyCheck)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colTimeCraft)}</th>
      <th>${escapeHtmlAllowBr(t.colComponents)}</th>
      <th>${escapeHtmlAllowBr(t.colItemDesc)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colPriceComponents)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colPrice)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colPriceItem)}</th>
    </tr>
  `;
  const emptyRow = `
    <tr>
      <td class="equip-fit equip-right">&nbsp;</td>
      <td class="equip-fit equip-left">&nbsp;</td>
      <td class="equip-fit equip-left">&nbsp;</td>
      <td class="equip-fit equip-left">&nbsp;</td>
      <td class="equip-fit equip-left">&nbsp;</td>
      <td class="equip-components">&nbsp;</td>
      <td class="equip-item-desc">&nbsp;</td>
      <td class="equip-fit equip-left">&nbsp;</td>
      <td class="equip-fit equip-left">&nbsp;</td>
      <td class="equip-fit equip-left">&nbsp;</td>
    </tr>
  `;
  const dataRows =
    vm.blueprints.length > 0
      ? vm.blueprints
          .map(
            (b) => `
          <tr>
            <td class="equip-fit equip-right">${escapeHtml(b.amount)}</td>
            <td class="equip-left">
              <div>${escapeHtml(b.name)}</div>
              ${b.group ? `<div class="cell-subtle">${escapeHtml(b.group)}</div>` : ''}
            </td>
            <td class="equip-fit equip-left">${escapeHtml(b.craftLevel)}</td>
            <td class="equip-fit equip-left">${escapeHtml(b.difficultyCheck)}</td>
            <td class="equip-fit equip-left">${escapeHtml(b.timeCraft)}</td>
            <td class="equip-components">${escapeHtml(b.components)}</td>
            <td class="equip-item-desc">${escapeHtml(b.itemDesc)}</td>
            <td class="equip-fit equip-left">${escapeHtml(b.priceComponents)}</td>
            <td class="equip-fit equip-left">${escapeHtml(b.price)}</td>
            <td class="equip-fit equip-left">${escapeHtml(b.priceItem)}</td>
          </tr>
        `,
          )
          .join('')
      : '';
  const rows = dataRows + emptyRow + emptyRow;

  return box(
    vm.i18n.section.blueprints,
    `
      <table class="equip-table equip-blueprints">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
        <thead>${headerRow}</thead>
        <tbody>${rows}</tbody>
      </table>
    `,
    'blueprints-box',
  );
}

function renderComponentsTables(vm: CharacterPdfPage3Vm, alchemyStyle: 'w1' | 'w2' = 'w2'): string {
  const t = vm.i18n.tables.components;

  const renderSubstanceCell = (substanceEn: string): string => {
    const url = substanceEn ? assetFormulaIngredientUrl(substanceEn, alchemyStyle) : null;
    if (url) return `<img class="formula-ingredient-img" src="${url}" alt="${escapeHtml(substanceEn)}" />`;
    return '&nbsp;&nbsp;&nbsp;';
  };

  const renderTable = (rows: CharacterPdfPage3Vm['componentsTables'][number]['rows']): string => `
    <table class="equip-table equip-components">
      <colgroup>
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
      </colgroup>
      <thead>
        <tr>
          <th class="equip-fit equip-right">${escapeHtmlAllowBr(t.colQty)}</th>
          <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colSub)}</th>
          <th>${escapeHtmlAllowBr(t.colName)}</th>
          <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colHarvestingComplexity)}</th>
          <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colWeight)}</th>
          <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colPrice)}</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map(
            (r) => `
          <tr>
            <td class="equip-fit equip-right">${escapeHtml(r.amount)}</td>
            <td class="equip-fit equip-left">${renderSubstanceCell(r.substanceEn)}</td>
            <td class="equip-left">${escapeHtml(r.name)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.harvestingComplexity)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.weight)}</td>
            <td class="equip-fit equip-left">${escapeHtml(r.price)}</td>
          </tr>
        `,
          )
          .join('')}
      </tbody>
    </table>
  `;

  const tables = vm.componentsTables.map((tvm) => box('', renderTable(tvm.rows), 'components-box')).join('');
  return `<div class="page3-components-group">${tables}</div>`;
}

function mutagenColorKey(raw: string): 'b' | 'r' | 'g' | '' {
  const s = (raw ?? '').toLowerCase();
  if (!s) return '';
  if (s.includes('крас') || s.includes('red')) return 'r';
  if (s.includes('зел') || s.includes('green')) return 'g';
  if (s.includes('голуб') || s.includes('син') || s.includes('blue')) return 'b';
  return '';
}

function renderMutagensTable(vm: CharacterPdfPage3Vm): string {
  const t = vm.i18n.tables.mutagens;
  const lang = vm.i18n.lang;

  const headerRow = `
    <tr>
      <th class="equip-fit equip-right">${escapeHtmlAllowBr(t.colQty)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colName)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colColor)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colAlchemyDc)}</th>
      <th>${escapeHtmlAllowBr(t.colEffect)}</th>
      <th>${escapeHtmlAllowBr(t.colMinorMutation)}</th>
    </tr>
  `;

  const dataRows = vm.mutagens
    .map((m) => {
      const key = mutagenColorKey(m.color);
      const letter = key === 'b' ? (lang === 'ru' ? 'С' : 'B') : key === 'r' ? (lang === 'ru' ? 'К' : 'R') : key === 'g' ? (lang === 'ru' ? 'З' : 'G') : '';
      const cls = key ? `mutagen-color mutagen-color-${key}` : 'mutagen-color';
      return `
        <tr>
          <td class="equip-fit equip-right">${escapeHtml(m.amount)}</td>
          <td class="equip-fit equip-left">${escapeHtml(m.name)}</td>
          <td class="equip-fit equip-left"><span class="${cls}">${escapeHtml(letter)}</span></td>
          <td class="equip-fit equip-left">${escapeHtml(m.alchemyDc)}</td>
          <td>${escapeHtml(m.effect)}</td>
          <td>${escapeHtml(m.minorMutation)}</td>
        </tr>
      `;
    })
    .join('');

  return box(
    vm.i18n.section.mutagens,
    `
      <table class="equip-table equip-mutagens">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col />
        </colgroup>
        <thead>${headerRow}</thead>
        <tbody>${dataRows}</tbody>
      </table>
    `,
    'mutagens-box',
  );
}

function renderTrophiesTable(vm: CharacterPdfPage3Vm): string {
  const t = vm.i18n.tables.trophies;
  const headerRow = `
    <tr>
      <th class="equip-fit equip-right">${escapeHtmlAllowBr(t.colQty)}</th>
      <th class="equip-fit equip-left">${escapeHtmlAllowBr(t.colName)}</th>
      <th>${escapeHtmlAllowBr(t.colEffect)}</th>
    </tr>
  `;
  const dataRows = vm.trophies
    .map(
      (tr) => `
        <tr>
          <td class="equip-fit equip-right">${escapeHtml(tr.amount)}</td>
          <td class="equip-fit equip-left">${escapeHtml(tr.name)}</td>
          <td>${escapeHtml(tr.effect)}</td>
        </tr>
      `,
    )
    .join('');

  return box(
    vm.i18n.section.trophies,
    `
      <table class="equip-table equip-trophies">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
        </colgroup>
        <thead>${headerRow}</thead>
        <tbody>${dataRows}</tbody>
      </table>
    `,
    'trophies-box',
  );
}

function renderGeneralGearTable(vm: CharacterPdfPage3Vm): string {
  const title = vm.i18n.section.generalGear;
  const t = vm.i18n.tables.generalGear;
  const rows =
    vm.generalGear.length > 0
      ? vm.generalGear
          .map(
            (g) => `
          <tr>
            <td class="equip-fit equip-right">${escapeHtml(g.amount)}</td>
            <td class="equip-left">
              <div>${escapeHtml(g.name)}</div>
              ${SHOW_GENERAL_GEAR_DESCRIPTION && g.description ? `<div class="cell-subtle">${escapeHtml(g.description)}</div>` : ''}
            </td>
            <td class="equip-fit equip-left">${escapeHtml(g.concealment)}</td>
            <td class="equip-fit equip-left">${escapeHtml(g.weight)}</td>
            <td class="equip-fit equip-left">${escapeHtml(g.price)}</td>
          </tr>
        `,
          )
          .join('')
      : `
          <tr>
            <td class="equip-fit equip-right">&nbsp;</td>
            <td>&nbsp;</td>
            <td class="equip-fit equip-left">&nbsp;</td>
            <td class="equip-fit equip-left">&nbsp;</td>
            <td class="equip-fit equip-left">&nbsp;</td>
          </tr>
        `;
  return box(
    title,
    `
      <table class="equip-table equip-general-gear">
        <colgroup>
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.vehicles.colQty)}</th>
            <th>${escapeHtml(t.colName)}</th>
            <th class="equip-fit equip-left">${escapeHtml(t.colConcealment)}</th>
            <th class="equip-fit equip-left">${escapeHtml(t.colWeight)}</th>
            <th class="equip-fit equip-left">${escapeHtml(t.colPrice)}</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `,
    'general-gear-box',
  );
}

function renderMoneyTable(vm: CharacterPdfPage3Vm): string {
  const title = vm.i18n.section.money;
  const t = vm.i18n.tables.money;
  const headers = [t.colCrowns, t.colOrens, t.colFlorens, t.colDucats, t.colBizants, t.colLintars];
  return box(
    title,
    `
      <table class="equip-table equip-money">
        <colgroup>
          <col /><col /><col /><col /><col /><col />
        </colgroup>
        <thead><tr>${headers.map((h) => `<th class="equip-fit equip-left">${escapeHtml(h)}</th>`).join('')}</tr></thead>
        <tbody>
          <tr>
            <td class="equip-fit equip-left">${escapeHtml(vm.money.crowns)}</td>
            <td class="equip-fit equip-left"></td>
            <td class="equip-fit equip-left"></td>
            <td class="equip-fit equip-left"></td>
            <td class="equip-fit equip-left"></td>
            <td class="equip-fit equip-left"></td>
          </tr>
        </tbody>
      </table>
    `,
    'money-box',
  );
}

function renderUpgradesTable(vm: CharacterPdfPage3Vm): string {
  if (vm.upgrades.length === 0) return '';
  const title = vm.i18n.section.upgrades;
  const t = vm.i18n.tables.upgrades;
  const rows = vm.upgrades
    .map(
      (u) => `
          <tr>
            <td class="equip-fit equip-right">${escapeHtml(u.amount)}</td>
            <td class="equip-fit equip-left">
              ${u.group ? `<div class="cell-subtle">${escapeHtml(u.group)}</div>` : ''}
              <div>${escapeHtml(u.name)}</div>
              ${u.target ? `<div class="cell-subtle">${escapeHtml(u.target)}</div>` : ''}
            </td>
            <td class="equip-effect">${escapeHtml(u.effects)}</td>
            <td class="equip-fit equip-left">${escapeHtml(u.slots)}</td>
            <td class="equip-fit equip-left">${escapeHtml(u.weight)}</td>
            <td class="equip-fit equip-left">${escapeHtml(u.price)}</td>
          </tr>
        `,
    )
    .join('');
  return box(
    title,
    `
      <table class="equip-table equip-upgrades">
        <colgroup>
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col />
          <col class="equip-fit" />
          <col class="equip-fit" />
          <col class="equip-fit" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-right">${escapeHtml(vm.i18n.tables.vehicles.colQty)}</th>
            <th class="equip-fit equip-left">${escapeHtml(t.colName)}</th>
            <th>${escapeHtml(t.colEffects)}</th>
            <th class="equip-fit equip-left">${escapeHtml(t.colSlots)}</th>
            <th class="equip-fit equip-left">${escapeHtml(t.colWeight)}</th>
            <th class="equip-fit equip-left">${escapeHtml(t.colPrice)}</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `,
    'upgrades-box',
  );
}

function renderPage2(vm: CharacterPdfPage2Vm, giftsInlineTplHtml = '', itemEffectsInlineTplHtml = ''): string {
  const loreHtml = renderLoreBlock(vm);
  const socialStatusHtml = renderSocialStatusTable(vm);
  const lifePathHtml = renderLifeEvents(vm);
  const styleHtml = renderStyleTable(vm);
  const valuesHtml = renderValuesTable(vm);
  const siblingsHtml = vm.siblings.length ? renderSiblings(vm) : '';

  return `
    <div class="page page2">
      <div class="page2-layout" id="page2-layout">
        <div class="page2-pack" id="page2-pack" data-cols="2" style="--page2-cols: 2;"></div>
        <div class="page2-row1">
          <div class="page2-cell page2-cell-left" id="page2-left">
            ${lifePathHtml}
          </div>
          <div class="page2-cell page2-cell-right" id="page2-right">
            <div class="page2-right-inner" id="page2-right-inner">
              ${loreHtml}
              ${socialStatusHtml}
              <div class="page2-style-values" id="page2-style-values">
                ${styleHtml}
                ${valuesHtml}
              </div>
            </div>
          </div>
        </div>
        <div class="page2-row2 page2-row2-hidden" id="page2-row2"></div>
        <div class="page2-siblings-row page2-hidden" id="page2-siblings-full">
          <div id="page2-siblings-col1"></div>
          <div class="page2-siblings-col-empty"></div>
        </div>
        <div class="page2-allies-row">${renderAllies(vm)}</div>
        <div class="page2-enemies-row">${renderEnemies(vm)}</div>
      </div>
      <template id="page2-siblings-tpl">${siblingsHtml}</template>
      <template id="page2-style-tpl">${styleHtml}</template>
      <template id="page2-values-tpl">${valuesHtml}</template>
      ${giftsInlineTplHtml ? `<template id="page2-gifts-tpl">${giftsInlineTplHtml}</template>` : ''}
      ${itemEffectsInlineTplHtml ? `<template id="page2-item-effects-tpl">${itemEffectsInlineTplHtml}</template>` : ''}
    </div>
  `;
}

function renderPage3(vm: CharacterPdfPage3Vm, alchemyStyle: 'w1' | 'w2' = 'w2'): string {
  return `
    <div class="page page3">
      <div class="page3-layout">
        <div class="page3-recipes-row">${renderRecipesTable(vm, alchemyStyle)}</div>
        <div class="page3-blueprints-row">${renderBlueprintsTable(vm)}</div>
        <div class="page3-components-row">${renderComponentsTables(vm, alchemyStyle)}</div>
        <div class="page3-support-group" id="page3-support-group">
          <div class="page3-support-col" id="page3-support-col1"></div>
          <div class="page3-support-col" id="page3-support-col2"></div>
          <div class="page3-support-stash" id="page3-support-stash">
            ${renderMoneyTable(vm)}
            ${renderVehiclesTable(vm)}
            ${vm.upgrades.length > 0 ? renderUpgradesTable(vm) : ''}
            ${vm.mutagens.length > 0 ? renderMutagensTable(vm) : ''}
            ${vm.trophies.length > 0 ? renderTrophiesTable(vm) : ''}
            ${renderGeneralGearTable(vm)}
          </div>
        </div>
      </div>
    </div>
  `;
}

function renderSpellsSignsTable(vm: CharacterPdfPage4Vm): string {
  const t = getMagic4Labels(vm);
  const rows = [...vm.spellsSigns, null];
  return `
    <table class="equip-table equip-magic4 equip-magic4-spells">
      <colgroup>
        <col class="equip-fit" /> <!-- name -->
        <col class="equip-fit" /> <!-- element -->
        <col class="equip-fit" /> <!-- sta cast -->
        <col class="equip-fit" /> <!-- sta keep -->
        <col class="equip-fit" /> <!-- time -->
        <col class="equip-fit" /> <!-- damage -->
        <col class="equip-fit" /> <!-- range -->
        <col class="equip-fit" /> <!-- form -->
        <col /> <!-- area (flex) -->
      </colgroup>
      <thead>
        <tr>
          <th class="equip-fit">${escapeHtml(t.name)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.element)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.staminaCast)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.staminaKeeping)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.effectTime)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.damage)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.distance)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.form)}</th>
          <th class="equip-left">${escapeHtml(t.zoneSize)}</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map((r) => {
            if (!r) {
              return `
                <tr>
                  <td class="equip-fit">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-left">&nbsp;</td>
                </tr>
              `;
            }
            const tooltip = r.tooltip?.trim() ?? '';
            const rowClass = tooltip ? ' class="magic4-main magic4-with-tooltip"' : ' class="magic4-main"';
            return `
              <tr${rowClass}>
                <td class="equip-fit">${escapeHtml(r.name)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.element)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.staminaCast)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.staminaKeeping)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.effectTime)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.damage)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.distance)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.form)}</td>
                <td class="equip-left">${escapeHtml(r.zoneSize)}</td>
              </tr>
              ${tooltip ? renderMagic4TooltipRow(9, tooltip) : ''}
            `;
          })
          .join('')}
      </tbody>
    </table>
  `;
}

function renderInvocationsTable(vm: CharacterPdfPage4Vm): string {
  const t = getMagic4Labels(vm);
  const rows = [...vm.invocations, null];
  return `
    <table class="equip-table equip-magic4 equip-magic4-invocations">
      <colgroup>
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col />
      </colgroup>
      <thead>
        <tr>
          <th class="equip-fit">${escapeHtml(t.name)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.group)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.staminaCast)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.staminaKeeping)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.damage)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.distance)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.zoneSize)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.form)}</th>
          <th class="equip-left">${escapeHtml(t.effectTime)}</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map((r) => {
            if (!r) {
              return `
                <tr>
                  <td class="equip-fit">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-left">&nbsp;</td>
                </tr>
              `;
            }
            const tooltip = r.tooltip?.trim() ?? '';
            const rowClass = tooltip ? ' class="magic4-main magic4-with-tooltip"' : ' class="magic4-main"';
            return `
              <tr${rowClass}>
                <td class="equip-fit">${escapeHtml(r.name)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.group)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.staminaCast)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.staminaKeeping)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.damage)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.distance)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.zoneSize)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.form)}</td>
                <td class="equip-left">${escapeHtml(r.effectTime)}</td>
              </tr>
              ${tooltip ? renderMagic4TooltipRow(9, tooltip) : ''}
            `;
          })
          .join('')}
      </tbody>
    </table>
  `;
}

function renderRitualsTable(vm: CharacterPdfPage4Vm): string {
  const t = getMagic4Labels(vm);
  const rows = [...vm.rituals, null];
  return `
    <table class="equip-table equip-magic4 equip-magic4-rituals">
      <colgroup>
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col />
      </colgroup>
      <thead>
        <tr>
          <th class="equip-fit">${escapeHtml(t.name)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.level)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.dc)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.preparingTime)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.staminaCast)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.staminaKeeping)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.zoneSize)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.form)}</th>
          <th class="equip-left">${escapeHtml(t.effectTime)}</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map((r) => {
            if (!r) {
              return `
                <tr>
                  <td class="equip-fit">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-left">&nbsp;</td>
                </tr>
              `;
            }
            const tooltip = r.tooltip?.trim() ?? '';
            const rowClass = tooltip ? ' class="magic4-main magic4-with-tooltip"' : ' class="magic4-main"';
            return `
              <tr${rowClass}>
                <td class="equip-fit">${escapeHtml(r.name)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.level)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.dc)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.preparingTime)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.staminaCast)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.staminaKeeping)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.zoneSize)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.form)}</td>
                <td class="equip-left">${escapeHtml(r.effectTime)}</td>
              </tr>
              ${tooltip ? renderMagic4TooltipRow(9, tooltip) : ''}
            `;
          })
          .join('')}
      </tbody>
    </table>
  `;
}

function renderHexesTable(vm: CharacterPdfPage4Vm): string {
  const t = getMagic4Labels(vm);
  const rows = [...vm.hexes, null];
  return `
    <table class="equip-table equip-magic4 equip-magic4-hexes">
      <colgroup>
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col />
      </colgroup>
      <thead>
        <tr>
          <th class="equip-fit">${escapeHtml(t.name)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.level)}</th>
          <th class="equip-left">${escapeHtml(t.staminaCast)}</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map((r) => {
            if (!r) {
              return `
                <tr>
                  <td class="equip-fit">&nbsp;</td>
                  <td class="equip-fit equip-left">&nbsp;</td>
                  <td class="equip-left">&nbsp;</td>
                </tr>
              `;
            }
            const tooltip = r.tooltip?.trim() ?? '';
            const rowClass = tooltip ? ' class="magic4-main magic4-with-tooltip"' : ' class="magic4-main"';
            return `
              <tr${rowClass}>
                <td class="equip-fit">${escapeHtml(r.name)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.level)}</td>
                <td class="equip-left">${escapeHtml(r.staminaCast)}</td>
              </tr>
              ${tooltip ? renderMagic4TooltipRow(3, tooltip) : ''}
            `;
          })
          .join('')}
      </tbody>
    </table>
  `;
}

function getMagic4Labels(vm: CharacterPdfPage4Vm): {
  name: string;
  element: string;
  level: string;
  group: string;
  staminaCast: string;
  staminaKeeping: string;
  damage: string;
  distance: string;
  zoneSize: string;
  form: string;
  preparingTime: string;
  dc: string;
  effectTime: string;
} {
  const c = vm.i18n.column;
  const lang = vm.i18n.lang;
  return {
    ...c,
    name: lang === 'ru' ? 'Имя' : 'Name',
    staminaCast: lang === 'ru' ? 'Вын' : 'STA',
    staminaKeeping: lang === 'ru' ? 'Вын+' : 'STA+',
    distance: lang === 'ru' ? 'Дист.' : 'Rng.',
    effectTime: lang === 'ru' ? 'Время' : 'Time',
  };
}

function renderMagic4TooltipRow(colspan: number, tooltip: string): string {
  const text = tooltip.trim();
  if (!text) return '';
  const html = escapeHtmlAllowBoldItalic(text.replaceAll('\r\n', '\n')).replaceAll('\n', '<br/>');
  return `
    <tr class="magic4-tooltip">
      <td colspan="${colspan}" class="magic4-tooltip-cell">${html}</td>
    </tr>
  `;
}

function renderGiftsTable(vm: CharacterPdfPage4Vm): string {
  const t = vm.i18n.gifts;
  const rows = vm.gifts;
  return `
    <table class="equip-table equip-magic4 equip-magic4-gifts">
      <colgroup>
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col class="equip-fit" />
        <col />
      </colgroup>
      <thead>
        <tr>
          <th class="equip-fit">${escapeHtml(t.colName)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.colGroup)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.colSl)}</th>
          <th class="equip-fit equip-left">${escapeHtml(t.colVigor)}</th>
          <th class="equip-left">${escapeHtml(t.colCost)}</th>
        </tr>
      </thead>
      <tbody>
        ${rows
          .map((r) => {
            const tooltip = (r.description ?? '').trim();
            const rowClass = tooltip ? ' class="magic4-main magic4-with-tooltip"' : ' class="magic4-main"';
            return `
              <tr${rowClass}>
                <td class="equip-fit">${escapeHtml(r.name)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.group)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.sl)}</td>
                <td class="equip-fit equip-left">${escapeHtml(r.vigor)}</td>
                <td class="equip-left">${escapeHtml(r.cost)}</td>
              </tr>
              ${tooltip ? renderMagic4TooltipRow(5, tooltip) : ''}
            `;
          })
          .join('')}
      </tbody>
    </table>
  `;
}

function renderItemEffectsGlossaryTable(vm: CharacterPdfPage4Vm): string {
  const rows = vm.itemEffects
    .map((e) => {
      const name = escapeHtml(e.name ?? '');
      const value = escapeHtml(e.value ?? '').replace(/\r?\n/g, '<br>');
      const body = value ? `<b>${name}</b> — ${value}` : `<b>${name}</b>`;
      return `
        <tr>
          <td class="item-effects-cell">${body}</td>
        </tr>
      `;
    })
    .join('');

  return `
    <table class="equip-table equip-item-effects">
      <colgroup><col /></colgroup>
      <tbody>${rows}</tbody>
    </table>
  `;
}

function renderPage4(vm: CharacterPdfPage4Vm): string {
  if (!vm.shouldRender) return '';
  const titles = vm.i18n.source;
  const spellsSignsTitle = `${titles.magicSpellsTitle} / ${titles.magicSignsTitle}`;

  return `
    <div class="page page4">
      <div class="page4-layout">
        ${vm.showSpellsSigns ? box(spellsSignsTitle, renderSpellsSignsTable(vm), 'magic4-spells-box') : ''}
        ${vm.showInvocations ? box(titles.invocationsPriestTitle, renderInvocationsTable(vm), 'magic4-invocations-box') : ''}
        ${vm.showRituals ? box(titles.magicRitualsTitle, renderRitualsTable(vm), 'magic4-rituals-box') : ''}
        ${vm.showHexes ? box(titles.magicHexesTitle, renderHexesTable(vm), 'magic4-hexes-box') : ''}
        ${vm.showGifts ? box(titles.magicGiftsTitle, renderGiftsTable(vm), 'magic4-gifts-box') : ''}
        ${vm.showItemEffects ? box(vm.i18n.effects.title, renderItemEffectsGlossaryTable(vm), 'item-effects-box') : ''}
      </div>
    </div>
  `;
}

export function renderCharacterPdfHtml(input: {
  page1: CharacterPdfPage1Vm;
  page2: CharacterPdfPage2Vm;
  page3: CharacterPdfPage3Vm;
  page4: CharacterPdfPage4Vm;
  options?: { alchemy_style?: 'w1' | 'w2' };
}): string {
  const vm = input.page1;
  const page2 = input.page2;
  const page3 = input.page3;
  const page4 = input.page4;
  const alchemyStyle = input.options?.alchemy_style ?? 'w2';
  const onlyGiftsMagic = page4.gifts.length > 0 && !page4.showSpellsSigns && !page4.showInvocations && !page4.showRituals && !page4.showHexes;
  const page2GiftsInlineTpl = onlyGiftsMagic
    ? box(page4.i18n.source.magicGiftsTitle, renderGiftsTable(page4), 'magic4-gifts-box magic4-gifts-inline')
    : '';
  const page2ItemEffectsInlineTpl = onlyGiftsMagic && page4.showItemEffects
    ? box(page4.i18n.effects.title, renderItemEffectsGlossaryTable(page4), 'item-effects-box item-effects-inline')
    : '';
  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${escapeHtml(vm.base.name)} — ${escapeHtml(vm.i18n.titleSuffix)}</title>
    <style>
      @page { size: A4; margin: 6mm; }
      * { box-sizing: border-box; }
      html, body { padding: 0; margin: 0; }
      body {
        font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial;
        color: #111827;
        background: white;
        font-size: 10.5px;
        line-height: 1.15;
      }

      .page {
        width: 100%;
        padding: 0;
        min-height: 285mm;
      }
      .page1 {
        min-height: 285mm;
        display: grid;
        grid-template-rows: auto 1fr;
        gap: 4mm;
      }
      .page2 {
        min-height: 285mm;
        break-before: page;
        page-break-before: always;
      }
      .page3 {
        min-height: 285mm;
        break-before: page;
        page-break-before: always;
        height: 285mm;
      }
      .page4 {
        min-height: 285mm;
        break-before: page;
        page-break-before: always;
      }
      .page2-layout { display: flex; flex-direction: column; gap: 3mm; }
      .page3-layout { display: flex; flex-direction: column; gap: 3mm; height: 100%; }
      .page4-layout { display: flex; flex-direction: column; gap: 3mm; height: 100%; }
      .page2-pack { display: none; }
      .page2-pack.page2-visible {
        display: grid;
        grid-template-columns: repeat(var(--page2-cols, 2), 1fr);
        gap: 4mm;
        align-items: start;
      }
      .page2-pack-col { min-height: 0; display: flex; flex-direction: column; gap: 3mm; }
      .page2-row1 { display: grid; grid-template-columns: 1fr 1fr; gap: 4mm; align-items: start; }
      .page2-cell { min-height: 0; display: flex; flex-direction: column; gap: 3mm; }
      .page2-right-inner { display: flex; flex-direction: column; gap: 3mm; flex: 1; min-height: 0; }
      .page2-style-values { display: flex; flex-direction: column; gap: 3mm; }
      .page2-row2 { display: grid; grid-template-columns: 1fr 1fr; gap: 4mm; }
      .page2-row2-hidden { display: none !important; }
      .page2-row2.page2-row2-visible { display: grid !important; }
      .page2-hidden { display: none !important; }
      .page-hidden { display: none !important; }
      .page2-siblings-row { display: grid; grid-template-columns: 1fr 1fr; gap: 4mm; }
      .page2-siblings-row.page2-visible { display: grid !important; }
      .page2-allies-row, .page2-enemies-row { margin-top: 0; }
      .page2-gifts-inline-wrap { width: 100%; }
      .page2-item-effects-inline-wrap { width: 100%; }
      .page2-separator { margin: 4mm 0; text-align: center; }
      .page2-separator-line {
        display: block;
        height: 4px;
        border: none;
        border-top: 1px solid #b8b8b8;
        border-bottom: 1px solid #b8b8b8;
        background: repeating-linear-gradient(
          90deg,
          transparent 0,
          transparent 3px,
          #a0a0a0 3px,
          #a0a0a0 4px
        );
        background-position: 0 50%;
      }
      .page3-recipes-row { min-width: 0; }
      .page3-components-group {
        display: grid;
        grid-template-columns: 1fr 1fr 1fr;
        gap: 3mm;
        align-items: start;
      }
      .page3-support-group {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 3mm;
        align-items: stretch;
        flex: 1;
        min-height: 0;
      }
      .page3-support-col { min-width: 0; display: flex; flex-direction: column; gap: 3mm; min-height: 0; }
      .page3-support-stash { display: none; }
      .mutagen-color {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 14px;
        height: 14px;
        border: 1px solid #111827;
        font-weight: 900;
        font-size: 9px;
        line-height: 1;
      }
      .mutagen-color-r { background: rgba(220,38,38,0.25); color: #111827; }
      .mutagen-color-g { background: rgba(34,197,94,0.25); color: #111827; }
      .mutagen-color-b { background: rgba(59,130,246,0.25); color: #111827; }
      .recipes-cell-toxicity { border-right: 3px solid black; }
      .formula-ingredient-img { width: 14px; height: 14px; vertical-align: middle; object-fit: contain; }
      .formula-legend-img { width: 14px; height: 14px; vertical-align: middle; object-fit: contain; }
      .recipes-legend-row td { border: none !important; border-top: 1px solid #666 !important; }
      .recipes-legend-cell { font-size: 9px; padding: 2px 4px; }
      .equip-table.equip-vehicles { table-layout: auto; width: 100%; }
      .equip-table.equip-recipes { table-layout: auto; width: 100%; }
      .equip-table.equip-blueprints { table-layout: auto; width: 100%; }
      .equip-table.equip-components { table-layout: auto; width: 100%; }
      .equip-table.equip-mutagens { table-layout: auto; width: 100%; }
      .equip-table.equip-trophies { table-layout: auto; width: 100%; }
      .equip-blueprints .equip-components { white-space: pre-line; overflow-wrap: anywhere; word-break: break-word; }
      .equip-blueprints .equip-item-desc { white-space: pre-line; overflow-wrap: anywhere; word-break: break-word; }
      .equip-recipes .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; }
      .equip-table.equip-general-gear { table-layout: auto; width: 100%; }
      .equip-table.equip-money { table-layout: fixed; width: 100%; }
      .equip-table.equip-upgrades { table-layout: auto; width: 100%; }
      .equip-table.equip-magic4 { table-layout: auto; width: 100%; }
      .equip-upgrades .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .cell-subtle { color: #6b7280; font-size: 9px; line-height: 1.1; }
      .equip-general-gear .cell-subtle, .equip-upgrades .cell-subtle { color: #9ca3af; }
      .social-status-cell { vertical-align: top; }
      .t-auto { table-layout: auto; }
      .t-fit-col { width: 1%; white-space: nowrap; }
      .stack { display: grid; gap: 3mm; }

      .grid-top {
        display: grid;
        grid-template-columns: 52mm 44.5mm 44.5mm 44.5mm;
        grid-column-gap: 4mm;
        grid-row-gap: 3mm;
        grid-template-rows: 46mm;
        align-items: stretch;
      }

      .pos-base { grid-column: 1; grid-row: 1; }
      .pos-main { grid-column: 2; grid-row: 1; }
      .pos-consumables { grid-column: 3; grid-row: 1; }
      .pos-avatar { grid-column: 4; grid-row: 1; }

      .box { border: 1px solid #111827; background: #fff; }
      .page1 .box { height: 100%; }
      .box-title {
        padding: 2px 4px;
        border-bottom: 1px solid #111827;
        font-weight: 800;
        font-size: 10px;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        background: #f3f4f6;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }
      .box-body { padding: 3px; }

      .kv { width: 100%; border-collapse: collapse; }
      .kv td { border-bottom: 1px solid #111827; padding: 2px 3px; }
      .kv tr:last-child td { border-bottom: 0; }
      .kv-k { width: 46%; font-weight: 800; }
      .kv-v { width: 54%; }

      .params-table { width: 100%; border-collapse: collapse; table-layout: fixed; }
      .params-table td { border-bottom: 1px solid #e5e7eb; padding: 2px 2px; }
      .params-table tr:last-child td { border-bottom: 0; }
      .subhead {
        border-bottom: 1px solid #111827 !important;
        font-weight: 900;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        background: #f3f4f6;
      }
      .comp-k { width: 40%; font-weight: 900; text-transform: uppercase; font-size: 9px; letter-spacing: 0.03em; }
      .comp-v { width: 10%; text-align: right; font-variant-numeric: tabular-nums; }

      .main-stats { width: 100%; border-collapse: collapse; table-layout: fixed; }
      .main-stats td { border-bottom: 1px solid #111827; padding: 2px 2px; }
      .main-stats tr:last-child td { border-bottom: 0; }
      .ms-k { width: 24%; font-weight: 900; text-transform: uppercase; }
      .ms-v { width: 26%; text-align: right; padding-right: 2px; font-variant-numeric: tabular-nums; }

      .consumables { width: 100%; border-collapse: collapse; }
      .consumables th, .consumables td { border: 1px solid #111827; padding: 3px; }
      .consumables thead th { background: #f3f4f6; text-transform: uppercase; font-size: 9px; letter-spacing: 0.06em; }
      .narrow { width: 11mm; }
      .t-right { text-align: right; font-variant-numeric: tabular-nums; }

      .avatar-box { height: 100%; }
      .page1 .avatar-box .box-body { height: calc(100% - 18px); }
      .avatar-placeholder {
        height: 100%;
        min-height: 0;
        border: 1px dashed #6b7280;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #6b7280;
        font-style: italic;
      }
      .avatar-img { width: 100%; height: 100%; object-fit: cover; display: block; }

      .grid-bottom {
        display: grid;
        grid-template-columns: 52mm 44.5mm 44.5mm 44.5mm;
        grid-template-rows: auto 1fr;
        column-gap: 4mm;
        row-gap: 2mm;
        min-height: 0;
      }

      .skills-column {
        border: 1px solid #111827;
        padding: 2px;
        overflow: hidden;
        min-height: 0;
        grid-column: 1;
        grid-row: 1 / span 2;
      }
      .skill-group { break-inside: avoid; page-break-inside: avoid; margin-bottom: 4px; }
      .skill-group-header {
        display: flex;
        justify-content: space-between;
        align-items: baseline;
        border: 1px solid #111827;
        background: #f9fafb;
        padding: 2px 3px;
      }
      .sg-title { font-weight: 900; text-transform: uppercase; font-size: 9px; }
      .sg-stat { font-variant-numeric: tabular-nums; }

      .skills { width: 100%; border-collapse: collapse; }
      .skills td { border-bottom: 1px solid #e5e7eb; padding: 0px 2px; vertical-align: top; }
      .skills tr:last-child td { border-bottom: 0; }
      .sk-name { width: 58%; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .sk-cur { width: 10%; text-align: right; font-variant-numeric: tabular-nums; }
      .sk-bonus { width: 14%; text-align: right; font-variant-numeric: tabular-nums; }
      .sk-base { width: 18%; text-align: right; font-variant-numeric: tabular-nums; color: #374151; }

      .prof-title-row {
        grid-column: 2 / span 3;
        grid-row: 1;
        font-weight: 900;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        font-size: 10px;
        margin: 0;
        align-self: end;
      }
      .prof-area {
        grid-column: 2 / span 3;
        grid-row: 2;
        min-height: 0;
        display: flex;
        flex-direction: column;
        gap: 3mm;
        overflow: hidden;
      }

      .prof-grid { display: grid; grid-template-columns: 44.5mm 44.5mm 44.5mm; gap: 4mm; }
      .prof-table { width: 100%; border-collapse: collapse; table-layout: fixed; }
      .prof-table th, .prof-table td { border: 1px solid #111827; padding: 2px 3px; }
      .prof-table thead th {
        font-weight: 900;
        text-transform: uppercase;
        font-size: 9px;
        letter-spacing: 0.06em;
        text-align: left;
      }
      .prof-skill { width: 78%; }
      .prof-val { width: 22%; }
      .prof-param { font-weight: 700; color: #374151; }

      .prof-col-blue { background: rgba(59,130,246,0.08); }
      .prof-col-green { background: rgba(16,185,129,0.08); }
      .prof-col-red { background: rgba(239,68,68,0.08); }

      .equip-area { display: flex; flex-direction: column; gap: 3mm; min-height: 0; }
      .equip-row { display: flex; gap: 3mm; align-items: flex-start; }
      .equip-row-left { flex: 0 0 auto; }
      .equip-row-right { flex: 1 1 auto; min-width: 0; }
      .equip-table { width: 100%; border-collapse: collapse; table-layout: fixed; font-size: 9.5px; }
      .equip-table th, .equip-table td { border: 1px solid #111827; padding: 2px 3px; }
      .equip-table thead th { font-weight: 900; text-transform: uppercase; font-size: 9px; letter-spacing: 0.06em; text-align: left; }
      .equip-table thead { display: table-header-group; }
      .equip-table tr { break-inside: avoid; page-break-inside: avoid; }
      .equip-table tbody tr { height: 14px; }
      .equip-check { text-align: center; }
      .equip-num { text-align: right; font-variant-numeric: tabular-nums; }
      .equip-name { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .equip-effect { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-size: 9px; }
      .equip-fit { width: 1%; white-space: nowrap; }
      .equip-left { text-align: left; }
      .equip-right { text-align: right; font-variant-numeric: tabular-nums; }
      .equip-weapons { table-layout: auto; }
      .equip-armors { table-layout: auto; }
      .equip-potions { table-layout: auto; }
      .weapon-name { white-space: normal; }
      .weapon-title { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .weapon-effects { margin-top: 1px; font-size: 9px; color: #374151; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .armor-name { white-space: normal; }
      .armor-title { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .armor-effects { margin-top: 1px; font-size: 9px; color: #374151; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .equip-potions tbody tr { height: auto; }
      .equip-potions tbody td { vertical-align: top; }
      .equip-potions .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .equip-weapons thead th { background: rgba(239,68,68,0.10); }
      .equip-armors thead th { background: rgba(59,130,246,0.10); }
      .equip-potions thead th { background: rgba(16,185,129,0.10); }
      .equip-magic thead th { background: rgba(168,85,247,0.10); }
      .equip-magic { table-layout: auto; }
      .equip-allies { table-layout: auto; }
      .equip-allies tbody tr { height: auto; }
      .equip-allies tbody td { vertical-align: top; }
      .equip-allies .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .equip-enemies { table-layout: auto; }
      .equip-enemies tbody tr { height: auto; }
      .equip-enemies tbody td { vertical-align: top; }
      .equip-life-events { table-layout: auto; }
      .equip-life-events tbody tr { height: auto; }
      .equip-life-events tbody td { vertical-align: top; }
      .equip-life-events .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .equip-style { table-layout: auto; }
      .equip-style tbody tr { height: auto; }
      .equip-style tbody td { vertical-align: top; }
      .equip-style .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .equip-values { table-layout: auto; }
      .equip-values tbody tr { height: auto; }
      .equip-values tbody td { vertical-align: top; }
      .equip-values .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .equip-siblings { table-layout: auto; }
      .equip-siblings tbody tr { height: auto; }
      .equip-siblings tbody td { vertical-align: top; }
      .equip-siblings .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .equip-bricks { width: 28mm; table-layout: fixed; margin-left: 0; }
      .equip-bricks tbody tr { height: 6mm; }
      .equip-bricks tbody td { padding: 1px; vertical-align: middle; text-align: center; border: 1px solid #111827; }
      .brick-cell { min-width: 0; min-height: 0; padding: 0 !important; text-align: left; }
      .brick-empty { border: none !important; padding: 0; background: transparent; }
      .brick-inner { height: 100%; width: 100%; display: flex; align-items: stretch; }
      .brick-img { height: 100%; width: auto; max-width: calc(100% - 6mm); display: block; object-fit: contain; }
      .brick-spacer { width: 6mm; flex: 0 0 6mm; }

      .notes-wrapper { flex: 1 1 auto; min-height: 0; }
      .notes-grid { height: 100%; display: grid; grid-template-columns: repeat(3, 1fr); gap: 4mm; }
      .notes-table { width: 100%; border-collapse: collapse; table-layout: fixed; }
      .notes-table th, .notes-table td { border: 1px solid #111827; padding: 2px 3px; }
      .notes-table thead th {
        background: rgba(180, 83, 9, 0.14);
        font-weight: 900;
        text-transform: uppercase;
        font-size: 9px;
        letter-spacing: 0.06em;
        text-align: left;
      }
      .notes-table tbody tr { height: 14px; }

      .lore-paras .p { margin: 0 0 2px 0; }
      .p-k { font-weight: 800; }
      .muted { color: #6b7280; }
      .reputation-muted { color: #e5e7eb; }
      .equip-social-status { table-layout: auto; }
      .social-status-box .box-title { background: rgba(249, 115, 22, 0.14); }
      .perks-box .perks-table { width: 100%; border-collapse: collapse; table-layout: auto; }
      .perks-box .perks-table th, .perks-box .perks-table td { border: 1px solid #111827; padding: 2px 3px; vertical-align: top; }
      .perks-box .perks-table thead th { background: rgba(249, 115, 22, 0.2); font-weight: 900; text-transform: uppercase; font-size: 9px; letter-spacing: 0.06em; }
      .perks-box .perks-table .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; }
      .lore-box .box-title,
      .life-box .box-title,
      .style-box .box-title,
      .values-box .box-title { background: rgba(59, 130, 246, 0.12); }
      .siblings-box .box-title { background: rgba(20, 184, 166, 0.14); }
      .allies-box .box-title { background: rgba(34, 197, 94, 0.14); }
      .enemies-box .box-title { background: rgba(239, 68, 68, 0.14); }
      .recipes-box .box-title { background: rgba(34,197,94,0.14); }
      .blueprints-box .box-title { background: rgba(139,90,43,0.12); }
      .money-box .box-title { background: rgba(249,115,22,0.14); }
      .upgrades-box .box-title { background: rgba(59,130,246,0.14); }
      .mutagens-box .box-title,
      .trophies-box .box-title { background: rgba(220,38,38,0.14); }
      .magic4-spells-box .box-title { background: rgba(147, 197, 253, 0.35); }
      .magic4-invocations-box .box-title { background: rgba(253, 186, 116, 0.35); }
      .magic4-rituals-box .box-title { background: rgba(196, 181, 253, 0.35); }
      .magic4-hexes-box .box-title { background: rgba(252, 165, 165, 0.35); }
      .magic4-gifts-box .box-title { background: rgba(110, 231, 183, 0.28); }
      .equip-table.equip-magic4 tbody tr.magic4-main.magic4-with-tooltip td { border-bottom-color: #d1d5db; }
      .equip-table.equip-magic4 tbody tr.magic4-tooltip td { border-top-color: #d1d5db; font-size: 9px; color: #374151; }
      .equip-table.equip-magic4 tbody tr.magic4-tooltip td.magic4-tooltip-cell { padding-top: 3px; padding-bottom: 3px; }
      .equip-table.equip-magic4 tbody tr.magic4-tooltip td.magic4-tooltip-cell b { font-weight: 900; }
      .equip-table.equip-magic4 tbody tr.magic4-tooltip td.magic4-tooltip-cell i { font-style: italic; }
      .item-effects-box .box-title { background: rgba(59, 130, 246, 0.12); }
      .equip-table.equip-item-effects { table-layout: auto; }
      .equip-table.equip-item-effects tbody tr { height: auto; break-inside: avoid; page-break-inside: avoid; }
      .equip-table.equip-item-effects td.item-effects-cell { white-space: normal; overflow-wrap: anywhere; word-break: break-word; line-height: 1.12; font-size: 9.5px; }
      .equip-table.equip-item-effects td.item-effects-cell b { font-weight: 900; }
      .t { width: 100%; border-collapse: collapse; table-layout: fixed; }
      .t th, .t td { border: 1px solid #111827; padding: 2px 3px; vertical-align: top; }
      .t thead th { background: #f3f4f6; font-weight: 900; text-transform: uppercase; font-size: 9px; letter-spacing: 0.06em; text-align: left; }
      .t-fit { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .t-wrap { white-space: normal; overflow-wrap: anywhere; word-break: break-word; }
    </style>
  </head>
  <body>
      ${renderPage1(vm)}
      ${renderPage2(page2, page2GiftsInlineTpl, page2ItemEffectsInlineTpl)}
      ${renderPage3(page3, alchemyStyle)}
      ${renderPage4(page4)}

      <script>
      (async () => {
        const waitForAssets = async () => {
          // Fonts can affect line wrapping/row heights, and images (even data URLs) may decode asynchronously.
          try {
            if (document.fonts && document.fonts.ready) {
              await document.fonts.ready;
            }
          } catch {}

          const imgs = Array.from(document.images || []);
          if (imgs.length === 0) return;

          const waitLoad = (img) => {
            if (img.complete) return Promise.resolve();
            return new Promise((resolve) => {
              img.addEventListener('load', resolve, { once: true });
              img.addEventListener('error', resolve, { once: true });
            });
          };

          await Promise.all(imgs.map(waitLoad));

          await Promise.all(
            imgs.map((img) => {
              try {
                return typeof img.decode === 'function' ? img.decode().catch(() => undefined) : Promise.resolve();
              } catch {
                return Promise.resolve();
              }
            }),
          );
        };

        const run = () => {
          const wrapper = document.getElementById('notes-wrapper');
          if (wrapper) {
            const tables = Array.from(wrapper.querySelectorAll('table.notes-table'));
            if (tables.length > 0) {
              const gridBottom = wrapper.closest('.grid-bottom') ?? document.querySelector('.grid-bottom');
              const wrapperRect = wrapper.getBoundingClientRect();
              const bottomRect = gridBottom ? gridBottom.getBoundingClientRect() : null;
              const bottomY = bottomRect ? bottomRect.bottom : wrapperRect.bottom;
              const available = bottomY - wrapperRect.top;
              if (Number.isFinite(available) && available > 0) {
                const headH = tables[0].tHead ? tables[0].tHead.getBoundingClientRect().height : 0;
                const tbody0 = tables[0].tBodies && tables[0].tBodies[0];
                const probe = document.createElement('tr');
                probe.appendChild(document.createElement('td'));
                tbody0.appendChild(probe);
                const rowH = probe.getBoundingClientRect().height || 14;
                tbody0.removeChild(probe);
                const SAFE_PX = 3; // be conservative to avoid clipping/overflow in print/PDF rounding
                const rows = Math.floor((available - headH - SAFE_PX) / rowH);
                if (rows > 0) {
                  wrapper.style.display = '';
                  const desired = headH + rows * rowH;
                  const clamped = Math.max(0, Math.floor(Math.min(available, desired)));
                  wrapper.style.height = String(clamped) + 'px';
                  for (const t of tables) {
                    t.tBodies[0].innerHTML = '';
                    for (let i = 0; i < rows; i++) {
                      const tr = document.createElement('tr');
                      tr.innerHTML = '<td>&nbsp;</td>';
                      t.tBodies[0].appendChild(tr);
                    }
                  }
                } else wrapper.style.display = 'none';
              } else wrapper.style.display = 'none';
            }
          }

          const layout = document.getElementById('page2-layout');
          if (layout) {
            const pack = document.getElementById('page2-pack');
            if (pack) {
              const siblingsTpl = document.getElementById('page2-siblings-tpl');

              const blocks = [];
              const priorityById = {
                socialStatus: 1,
                lore: 2,
                lifePath: 3,
                siblings: 4,
                style: 5,
                values: 6,
              };
              const add = (id, selector) => {
                const el = layout.querySelector(selector);
                if (el) blocks.push({ id, priority: priorityById[id] ?? 1000 + blocks.length, order: blocks.length, el });
              };

              // The group of half-width blocks we want to pack tightly on page 2.
              add('lifePath', '.life-box');
              add('lore', '.lore-box');
              add('socialStatus', '.social-status-box');
              add('style', '.style-box');
              add('values', '.values-box');

              if (siblingsTpl && typeof siblingsTpl.innerHTML === 'string' && siblingsTpl.innerHTML.trim()) {
                const wrap = document.createElement('div');
                wrap.innerHTML = siblingsTpl.innerHTML.trim();
                const sibEl = wrap.firstElementChild;
                if (sibEl) blocks.push({ id: 'siblings', priority: priorityById.siblings ?? 1000 + blocks.length, order: blocks.length, el: sibEl });
              }

              const parsePx = (value) => {
                const n = Number.parseFloat(String(value || ''));
                return Number.isFinite(n) ? n : 0;
              };

              const cols = (() => {
                const raw = pack.getAttribute('data-cols') || pack.dataset.cols || '2';
                const n = Number.parseInt(raw, 10);
                return Number.isFinite(n) && n > 0 ? n : 2;
              })();
              pack.style.setProperty('--page2-cols', String(cols));

              const measureHeights = (colWidthPx) => {
                const probe = document.createElement('div');
                probe.style.cssText = 'position:absolute;visibility:hidden;left:-10000px;top:-10000px;';
                probe.style.width = String(Math.max(1, Math.floor(colWidthPx))) + 'px';
                document.body.appendChild(probe);

                try {
                  return blocks.map((b) => {
                    const clone = b.el.cloneNode(true);
                    probe.appendChild(clone);
                    const h = clone.getBoundingClientRect().height;
                    probe.removeChild(clone);
                    return { ...b, height: Number.isFinite(h) ? Math.max(0, h) : 0 };
                  });
                } finally {
                  probe.remove();
                }
              };

              const assignTwoColsOptimal = (items) => {
                const weights = items.map((it) => Math.max(0, Math.round(it.height)));
                const total = weights.reduce((a, b) => a + b, 0);
                const prevIdx = new Int32Array(total + 1);
                const prevSum = new Int32Array(total + 1);
                for (let i = 0; i < prevIdx.length; i++) prevIdx[i] = -1;
                prevIdx[0] = -2;

                for (let i = 0; i < weights.length; i++) {
                  const w = weights[i];
                  for (let s = total - w; s >= 0; s--) {
                    if (prevIdx[s] !== -1 && prevIdx[s + w] === -1) {
                      prevIdx[s + w] = i;
                      prevSum[s + w] = s;
                    }
                  }
                }

                let bestS = 0;
                let bestMax = Number.POSITIVE_INFINITY;
                let bestDiff = Number.POSITIVE_INFINITY;
                for (let s = 0; s <= total; s++) {
                  if (prevIdx[s] === -1) continue;
                  const maxH = Math.max(s, total - s);
                  const diff = Math.abs(total - 2 * s);
                  if (maxH < bestMax || (maxH === bestMax && (diff < bestDiff || (diff === bestDiff && s < bestS)))) {
                    bestMax = maxH;
                    bestDiff = diff;
                    bestS = s;
                  }
                }

                const inLeft = new Array(items.length).fill(false);
                let cur = bestS;
                while (cur > 0) {
                  const i = prevIdx[cur];
                  if (i < 0) break;
                  inLeft[i] = true;
                  cur = prevSum[cur];
                }

                const out = [[], []];
                for (let i = 0; i < items.length; i++) out[inLeft[i] ? 0 : 1].push(items[i]);
                return out;
              };

              const assignGreedy = (items) => {
                const byHeight = items
                  .slice()
                  .sort((a, b) => (b.height - a.height) || (a.order - b.order));
                const heights = new Array(cols).fill(0);
                const out = Array.from({ length: cols }, () => []);
                for (const item of byHeight) {
                  let bestCol = 0;
                  for (let c = 1; c < cols; c++) if (heights[c] < heights[bestCol]) bestCol = c;
                  out[bestCol].push(item);
                  heights[bestCol] += item.height;
                }
                return out;
              };

              const buildPackedColumns = (itemsByCol) => {
                pack.innerHTML = '';
                const colEls = [];
                for (let c = 0; c < cols; c++) {
                  const colEl = document.createElement('div');
                  colEl.className = 'page2-pack-col';
                  colEls.push(colEl);
                  pack.appendChild(colEl);
                }

                for (let c = 0; c < itemsByCol.length; c++) {
                  const ordered = itemsByCol[c]
                    .slice()
                    .sort((a, b) => (a.priority - b.priority) || (a.order - b.order));
                  for (const item of ordered) colEls[c].appendChild(item.el);
                }
              };

              if (blocks.length > 0) {
                pack.classList.add('page2-visible');
                const packRect = pack.getBoundingClientRect();
                const cs = getComputedStyle(pack);
                const gapPx = parsePx(cs.columnGap || cs.gap || '0');
                const colWidth = (packRect.width - gapPx * (cols - 1)) / cols;

                const measured = measureHeights(colWidth);
                const itemsByCol = cols === 2 && measured.length <= 18 ? assignTwoColsOptimal(measured) : assignGreedy(measured);
                buildPackedColumns(itemsByCol);

                // Remove legacy wrappers that contained the old branching layout logic.
                const row1 = layout.querySelector('.page2-row1');
                const row2 = document.getElementById('page2-row2');
                const siblingsFull = document.getElementById('page2-siblings-full');
                if (row1) row1.remove();
                if (row2) row2.remove();
                if (siblingsFull) siblingsFull.remove();

                // If the character has only ONE magic table (gifts), try to inline it on page 2 (near the Lore block).
                // If present, also try to inline the item effects glossary right after it.
                // If everything fits, hide page 4 entirely so we don't start a new page.
                const giftsTpl = document.getElementById('page2-gifts-tpl');
                if (giftsTpl && giftsTpl.tagName === 'TEMPLATE' && giftsTpl.innerHTML && giftsTpl.innerHTML.trim()) {
                  const page2El = layout.closest('.page') || document.querySelector('.page.page2');
                  const page4El = document.querySelector('.page.page4');
                  const frag = giftsTpl.content ? giftsTpl.content.cloneNode(true) : null;
                  if (page2El && frag) {
                    const wrap = document.createElement('div');
                    wrap.className = 'page2-gifts-inline-wrap';
                    wrap.appendChild(frag);

                    // IMPORTANT: this is a full-width table. Place it after Allies/Enemies blocks on page 2,
                    // not inside the packed half-width grid.
                    const enemiesRow = layout.querySelector && layout.querySelector('.page2-enemies-row');
                    if (enemiesRow && enemiesRow.parentElement) {
                      enemiesRow.parentElement.insertBefore(wrap, enemiesRow.nextSibling);
                    } else {
                      layout.appendChild(wrap);
                    }

                    const EPS_PX = 3.0;
                    const page2Bottom = page2El.getBoundingClientRect().bottom - EPS_PX;

                    const effectsTpl = document.getElementById('page2-item-effects-tpl');
                    const effectsFrag = effectsTpl && effectsTpl.tagName === 'TEMPLATE' && effectsTpl.innerHTML && effectsTpl.innerHTML.trim() && effectsTpl.content
                      ? effectsTpl.content.cloneNode(true)
                      : null;

                    let effectsWrap = null;
                    if (effectsFrag) {
                      effectsWrap = document.createElement('div');
                      effectsWrap.className = 'page2-item-effects-inline-wrap';
                      effectsWrap.appendChild(effectsFrag);
                      if (wrap.parentElement) {
                        wrap.parentElement.insertBefore(effectsWrap, wrap.nextSibling);
                      } else {
                        layout.appendChild(effectsWrap);
                      }
                    }

                    const bottomNow = (effectsWrap ?? wrap).getBoundingClientRect().bottom;
                    const fits = Number.isFinite(page2Bottom) && Number.isFinite(bottomNow) && bottomNow <= page2Bottom;

                    if (fits) {
                      if (page4El) page4El.classList.add('page-hidden');
                    } else {
                      if (effectsWrap) effectsWrap.remove();
                      wrap.remove();
                    }
                  }
                }
              }
            }

            document.querySelectorAll('template').forEach(t => t.remove());
          }

          const page3SupportGroup = document.getElementById('page3-support-group');
          if (page3SupportGroup) {
            const stash = document.getElementById('page3-support-stash');
            const col1 = document.getElementById('page3-support-col1');
            const col2 = document.getElementById('page3-support-col2');

            if (stash && col1 && col2) {
              const EPS = 18; // be conservative to avoid spilling due to fractional print rounding

              // IMPORTANT: use a fixed page boundary for all "fits in page" checks.
              // Using the support group's own rect is incorrect because it grows as we append rows,
              // making the boundary "move" and causing occasional overflow by a few rows.
              const page3Root =
                page3SupportGroup.closest('.page.page3') ?? document.querySelector('.page.page3');
              const boundaryEl = page3Root ?? page3SupportGroup;

              const boundaryBottom = () => {
                const r = boundaryEl.getBoundingClientRect();
                return r.bottom - EPS;
              };

              const colContentBottom = (colEl) => {
                const last = colEl.lastElementChild;
                if (last) return last.getBoundingClientRect().bottom;
                return colEl.getBoundingClientRect().top;
              };

              const fitsLastChild = (colEl) => {
                const last = colEl.lastElementChild;
                if (!last) return true;
                return last.getBoundingClientRect().bottom <= boundaryBottom();
              };

              const buildGeneralGearEmptyRow = () => {
                const tr = document.createElement('tr');
                tr.dataset.padRow = '1';
                tr.innerHTML =
                  '<td class="equip-fit equip-right">&nbsp;</td>' +
                  '<td>&nbsp;</td>' +
                  '<td class="equip-fit equip-left">&nbsp;</td>' +
                  '<td class="equip-fit equip-left">&nbsp;</td>' +
                  '<td class="equip-fit equip-left">&nbsp;</td>';
                return tr;
              };

              const padGeneralGearToBottom = (gearBox) => {
                const table = gearBox && gearBox.querySelector && gearBox.querySelector('table.equip-general-gear');
                const tbody = table && table.tBodies && table.tBodies[0];
                if (!tbody) return;

                // Ensure there's at least one row to measure/pad from.
                if (tbody.rows.length === 0) tbody.appendChild(buildGeneralGearEmptyRow());

                const isPadRow = (tr) => Boolean(tr && tr.dataset && tr.dataset.padRow === '1');

                const measurePadRowHeight = () => {
                  const probe = buildGeneralGearEmptyRow();
                  tbody.appendChild(probe);
                  const h = probe.getBoundingClientRect().height;
                  tbody.removeChild(probe);
                  return Number.isFinite(h) && h > 0 ? h : 16;
                };

                // NOTE: Chrome's printed pagination can be slightly more strict than DOM measurements
                // (especially with tables + repeating headers). Keep a conservative buffer in "row units"
                // so we never create a tiny spill page with a few empty rows.
                const padRowH = measurePadRowHeight();
                const BOTTOM_BUFFER_ROWS = 7;
                const bottomBufferPx = Math.max(12, Math.ceil(padRowH * BOTTOM_BUFFER_ROWS + 2));
                const safeBoundaryBottom = () => boundaryBottom() - bottomBufferPx;

                // Iteratively add rows until the next one would overflow.
                // (The arithmetic approach is fragile because row height can change with wrapping/images/fonts.)
                const MAX_PAD_ROWS = 260; // safety guard (~3 pages worth of tiny rows)
                for (let i = 0; i < MAX_PAD_ROWS; i++) {
                  const boundary = safeBoundaryBottom();
                  const before = gearBox.getBoundingClientRect().bottom;
                  if (!Number.isFinite(boundary) || !Number.isFinite(before)) break;
                  if (before >= boundary) break;

                  const probe = buildGeneralGearEmptyRow();
                  tbody.appendChild(probe);
                  const after = gearBox.getBoundingClientRect().bottom;

                  // If appending doesn't grow the box, stop to avoid infinite loops.
                  if (!(Number.isFinite(after) && after > before + 0.2)) {
                    tbody.removeChild(probe);
                    break;
                  }

                  if (after > boundary) {
                    tbody.removeChild(probe);
                    break;
                  }
                }

                // Final safeguard: if we still spill, remove ONLY padding rows from the bottom.
                for (let i = 0; i < MAX_PAD_ROWS; i++) {
                  const boundary = safeBoundaryBottom();
                  if (gearBox.getBoundingClientRect().bottom <= boundary) break;
                  const last = tbody.rows[tbody.rows.length - 1];
                  if (!last || !isPadRow(last)) break;
                  tbody.deleteRow(tbody.rows.length - 1);
                }
              };

              const pick = (selector) => stash.querySelector(selector);
              const firstColumnOrder = [
                '.money-box',
                '.vehicles-box',
                '.upgrades-box',
                '.mutagens-box',
                '.trophies-box',
              ];

              let useCol2 = false;
              for (const sel of firstColumnOrder) {
                const el = pick(sel);
                if (!el) continue;
                if (!useCol2) {
                  col1.appendChild(el);
                  if (!fitsLastChild(col1)) {
                    col1.removeChild(el);
                    useCol2 = true;
                    col2.appendChild(el);
                  }
                } else {
                  col2.appendChild(el);
                }
              }

              const gearBox = pick('.general-gear-box');
              if (gearBox) {
                col2.appendChild(gearBox);
                padGeneralGearToBottom(gearBox);

                // Add an extra empty-only General Gear table to col1 if it fits (to fill remaining space).
                const clone = gearBox.cloneNode(true);
                const cloneTable = clone.querySelector && clone.querySelector('table.equip-general-gear');
                const cloneTbody = cloneTable && cloneTable.tBodies && cloneTable.tBodies[0];
                if (cloneTbody) {
                  cloneTbody.innerHTML = '';
                  cloneTbody.appendChild(buildGeneralGearEmptyRow());
                }
                const measureMinHeight = (el, widthPx) => {
                  const probe = document.createElement('div');
                  probe.style.cssText = 'position:absolute;visibility:hidden;left:-10000px;top:-10000px;';
                  probe.style.width = String(Math.max(1, Math.floor(widthPx))) + 'px';
                  document.body.appendChild(probe);
                  try {
                    probe.appendChild(el);
                    const h = el.getBoundingClientRect().height;
                    probe.removeChild(el);
                    return Number.isFinite(h) ? h : 0;
                  } finally {
                    probe.remove();
                  }
                };

                const col1Width = col1.getBoundingClientRect().width || page3SupportGroup.getBoundingClientRect().width / 2;
                const remainingCol1 = boundaryBottom() - colContentBottom(col1);
                const minH = measureMinHeight(clone, col1Width);

                const SAFE_MIN_PX = 16;
                if (remainingCol1 >= minH + SAFE_MIN_PX) {
                  col1.appendChild(clone);
                  if (!fitsLastChild(col1)) {
                    col1.removeChild(clone);
                  } else {
                    padGeneralGearToBottom(clone);
                    if (!fitsLastChild(col1)) col1.removeChild(clone);
                  }
                }
              }

              // Cleanup the stash (kept hidden in case something relies on it).
              stash.innerHTML = '';
            }
          }

        };

        // Ensure layout-affecting assets are ready before we measure/pad to the bottom of the page.
        await waitForAssets();

        requestAnimationFrame(() => requestAnimationFrame(() => {
          run();
          // One more frame to let DOM moves/padding settle before signaling Playwright.
          requestAnimationFrame(() => { window.__pdfReady = true; });
        }));
      })();
    </script>
  </body>
</html>`;
}
