import type { CharacterPdfPage1Vm } from '../viewModel.js';

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
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

function renderBaseInfo(vm: CharacterPdfPage1Vm): string {
  const rows: Array<[string, string]> = [
    ['Имя', vm.base.name],
    ['Раса', vm.base.race],
    ['Пол', vm.base.gender],
    ['Возраст', vm.base.age],
    ['Профессия', vm.base.profession],
    ['Определяющий навык', vm.base.definingSkill],
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

function renderComputed(vm: CharacterPdfPage1Vm): string {
  const items: Array<[string, string]> = [
    ['Бег', vm.computed.run],
    ['Прыжок', vm.computed.leap],
    ['Устойчивость', vm.computed.stability],
    ['Удар рукой', vm.computed.punch],
    ['Удар ногой', vm.computed.kick],
    ['Отдых', vm.computed.rest],
    ['Энергия (Vigor)', vm.computed.vigor],
  ];

  const cells = items.concat(new Array(Math.max(0, 8 - items.length)).fill(['', '']));
  const row = (start: number) => `
    <tr>
      <td class="comp-k">${escapeHtml(cells[start][0] || '')}</td>
      <td class="comp-v">${escapeHtml(cells[start][1] || '')}</td>
      <td class="comp-k">${escapeHtml(cells[start + 1][0] || '')}</td>
      <td class="comp-v">${escapeHtml(cells[start + 1][1] || '')}</td>
    </tr>
  `;

  return `
    <table class="computed-table">
      <tbody>
        ${row(0)}
        ${row(2)}
        ${row(4)}
        ${row(6)}
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
    ['бег', vm.computed.run],
    ['прыж.', vm.computed.leap],
    ['уст', vm.computed.stability],
    ['уд.н.', vm.computed.kick],
    ['Отдых', vm.computed.rest],
    ['уд.р.', vm.computed.punch],
    ['Энергия', vm.computed.vigor],
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
        <tr><td class="subhead" colspan="4">Основные параметры</td></tr>
        ${mainRows.join('')}
        <tr><td class="subhead" colspan="4">Доп. параметры</td></tr>
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
          <th>Параметр</th>
          <th class="narrow">MAX</th>
          <th class="narrow">CUR</th>
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
  return `<div class="avatar-placeholder">Аватар</div>`;
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

function renderEquipment(vm: CharacterPdfPage1Vm): string {
  const weaponRowsWanted = Math.max(vm.equipment.weapons.length + 3, 3);
  const armorRowsWanted = Math.max(vm.equipment.armors.length + 3, 3);
  const potionRowsWanted = Math.max(vm.equipment.potions.length + 3, 3);

  const weaponRows = new Array(weaponRowsWanted).fill(null).map((_, i) => vm.equipment.weapons[i] ?? null);
  const armorRows = new Array(armorRowsWanted).fill(null).map((_, i) => vm.equipment.armors[i] ?? null);
  const potionRows = new Array(potionRowsWanted).fill(null).map((_, i) => vm.equipment.potions[i] ?? null);

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
            <th class="equip-fit equip-right">&#10003;</th>
            <th class="equip-fit equip-right">#</th>
            <th>Оружие</th>
            <th class="equip-fit equip-left">Урон</th>
            <th class="equip-fit equip-left">Тип</th>
            <th class="equip-fit equip-left">Н</th>
            <th class="equip-fit equip-left">Хват</th>
            <th class="equip-fit equip-left">Скр</th>
            <th class="equip-fit equip-left">УБ</th>
            <th class="equip-fit equip-left">Вес</th>
            <th class="equip-fit equip-left">Цена</th>
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
            <th class="equip-fit equip-right">&#10003;</th>
            <th class="equip-fit equip-right">#</th>
            <th>Броня</th>
            <th class="equip-fit equip-left">ПБ</th>
            <th class="equip-fit equip-left">СД</th>
            <th class="equip-fit equip-left">УБ</th>
            <th class="equip-fit equip-left">Вес</th>
            <th class="equip-fit equip-left">Цена</th>
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

      <table class="equip-table equip-potions">
        <colgroup>
          <col style="width:6mm" />
          <col style="width:26mm" />
          <col style="width:10mm" />
          <col style="width:14mm" />
          <col />
          <col style="width:10mm" />
          <col style="width:12mm" />
        </colgroup>
        <thead>
          <tr>
            <th class="equip-fit equip-right">#</th>
            <th class="equip-fit equip-right">Алхимия</th>
            <th class="equip-fit equip-right">Токс</th>
            <th class="equip-fit equip-right">Время</th>
            <th>Эффект</th>
            <th class="equip-fit equip-left">Вес</th>
            <th class="equip-fit equip-left">Цена</th>
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
    </div>
  `;
}

export function renderCharacterPage1Html(vm: CharacterPdfPage1Vm): string {
  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${escapeHtml(vm.base.name)} — Character Sheet</title>
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
        height: 297mm;
        padding: 6mm;
        display: grid;
        grid-template-rows: auto 1fr;
        gap: 4mm;
      }

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
      .equip-potions { table-layout: fixed; }
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
    </style>
  </head>
  <body>
    <div class="page">
      <div class="grid-top">
        <div class="pos-base">${box('Базовые данные', renderBaseInfo(vm))}</div>
        <div class="pos-main">${box('', renderParamsCombined(vm))}</div>
        <div class="pos-consumables">${box('Расходуемые', renderConsumables(vm))}</div>
        <div class="pos-avatar">${box('Аватар', renderAvatar(vm), 'avatar-box')}</div>
      </div>

      <div class="grid-bottom">
        <div class="skills-column">
          ${renderSkillGroups(vm)}
        </div>
        <div class="prof-title-row">${escapeHtml('Профессиональные навыки')}</div>
        <div class="prof-area">
          ${renderProfessional(vm)}
          ${renderEquipment(vm)}
        </div>
      </div>
    </div>
  </body>
</html>`;
}
