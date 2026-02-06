import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import type { CharacterPdfPage1Vm } from '../viewModel.js';
import type { CharacterPdfPage2Vm } from '../viewModelPage2.js';

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
] as const;

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
  const filename = `${englishName}.webp`;
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
  const tokens = formulaEn.trim().split(/\s+/);
  return tokens
    .map((token) => {
      const name = token.trim();
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
  const rows: Array<[string, string]> = [
    [vm.i18n.base.name, vm.base.name],
    [vm.i18n.base.race, vm.base.race],
    [vm.i18n.base.gender, vm.base.gender],
    [vm.i18n.base.age, vm.base.age],
    [vm.i18n.base.profession, vm.base.profession],
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
      const statValue = renderStatValue(group.stat.cur, group.stat.bonus, group.stat.raceBonus);
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
      ${renderNotes(vm.i18n.tables.notes.title)}
      ` : ''}
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

function renderVehiclesTable(vm: CharacterPdfPage2Vm): string {
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
      <table class="equip-table equip-vehicles table-header-pale-gray">
        <colgroup>${colgroup.join('')}</colgroup>
        <thead><tr>${headerCells.join('')}</tr></thead>
        <tbody>${rows}</tbody>
      </table>
    `,
    'vehicles-box',
  );
}

function renderRecipesTable(vm: CharacterPdfPage2Vm, alchemyStyle: 'w1' | 'w2' = 'w2'): string {
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
  const rows =
    vm.recipes.length > 0
      ? dataRows + emptyRecipeRow + emptyRecipeRow + emptyRecipeRow
      : emptyRecipeRow;
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
      <table class="equip-table equip-recipes table-header-pale-brown">
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

function renderPage2(vm: CharacterPdfPage2Vm, alchemyStyle: 'w1' | 'w2' = 'w2'): string {
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
        <div class="page2-separator" aria-hidden="true"><span class="page2-separator-line"></span></div>
        <div class="page2-vehicles-recipes-row">
          <div class="page2-vehicles-cell">${renderVehiclesTable(vm)}</div>
          <div class="page2-recipes-cell">${renderRecipesTable(vm, alchemyStyle)}</div>
        </div>
      </div>
      <template id="page2-siblings-tpl">${siblingsHtml}</template>
      <template id="page2-style-tpl">${styleHtml}</template>
      <template id="page2-values-tpl">${valuesHtml}</template>
    </div>
  `;
}

export function renderCharacterPdfHtml(input: {
  page1: CharacterPdfPage1Vm;
  page2: CharacterPdfPage2Vm;
  options?: { alchemy_style?: 'w1' | 'w2' };
}): string {
  const vm = input.page1;
  const page2 = input.page2;
  const alchemyStyle = input.options?.alchemy_style ?? 'w2';
  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${escapeHtml(vm.base.name)} — ${escapeHtml(vm.i18n.titleSuffix)}</title>
    <style>
      @page { size: A4; margin: 0; }
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
        width: 210mm;
        padding: 6mm;
      }
      .page1 {
        height: 297mm;
        display: grid;
        grid-template-rows: auto 1fr;
        gap: 4mm;
      }
      .page2 {
        height: 297mm;
        break-before: page;
        page-break-before: always;
      }
      .page2-layout { display: flex; flex-direction: column; gap: 3mm; }
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
      .page2-siblings-row { display: grid; grid-template-columns: 1fr 1fr; gap: 4mm; }
      .page2-siblings-row.page2-visible { display: grid !important; }
      .page2-allies-row, .page2-enemies-row { margin-top: 0; }
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
      .page2-vehicles-recipes-row {
        display: flex;
        flex-direction: column;
        gap: 3mm;
      }
      .page2-vehicles-cell { width: 50%; max-width: 50%; }
      .page2-recipes-cell { width: 100%; }
      .table-header-pale-gray thead th { background: rgba(0,0,0,0.06); }
      .table-header-pale-brown thead th { background: rgba(139,90,43,0.12); }
      .recipes-cell-toxicity { border-right: 3px solid black; }
      .formula-ingredient-img { width: 14px; height: 14px; vertical-align: middle; object-fit: contain; }
      .formula-legend-img { width: 14px; height: 14px; vertical-align: middle; object-fit: contain; }
      .recipes-legend-row td { border: none !important; border-top: 1px solid #666 !important; }
      .recipes-legend-cell { font-size: 9px; padding: 2px 4px; }
      .equip-table.equip-vehicles { table-layout: auto; width: auto; }
      .equip-table.equip-recipes { table-layout: auto; width: 100%; }
      .equip-recipes .equip-effect { white-space: normal; overflow-wrap: anywhere; word-break: break-word; }
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

      .box { border: 1px solid #111827; background: #fff; height: 100%; }
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
      .avatar-box .box-body { height: calc(100% - 18px); }
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
      .t { width: 100%; border-collapse: collapse; table-layout: fixed; }
      .t th, .t td { border: 1px solid #111827; padding: 2px 3px; vertical-align: top; }
      .t thead th { background: #f3f4f6; font-weight: 900; text-transform: uppercase; font-size: 9px; letter-spacing: 0.06em; text-align: left; }
      .t-fit { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .t-wrap { white-space: normal; overflow-wrap: anywhere; word-break: break-word; }
    </style>
  </head>
  <body>
    ${renderPage1(vm)}
    ${renderPage2(page2, alchemyStyle)}

    <script>
      (() => {
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
                const rows = Math.floor((available - headH - 2) / rowH);
                if (rows > 0) {
                  wrapper.style.display = '';
                  // Use ceil to avoid clipping the last row due to fractional pixel rounding (print/PDF).
                  wrapper.style.height = String(Math.ceil(headH + rows * rowH + 2)) + 'px';
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
              }
            }

            document.querySelectorAll('template').forEach(t => t.remove());
          }
        };
        requestAnimationFrame(() => requestAnimationFrame(() => {
          run();
          requestAnimationFrame(() => { window.__pdfReady = true; });
        }));
      })();
    </script>
  </body>
</html>`;
}
