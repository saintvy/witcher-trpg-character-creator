import type { CharacterPdfViewModel } from '../viewModel.js';

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function richText(value: string): string {
  // Keep only a tiny whitelist of formatting tags emitted by our generator.
  const escaped = escapeHtml(value);
  return escaped
    .replaceAll('&lt;b&gt;', '<b>')
    .replaceAll('&lt;/b&gt;', '</b>')
    .replaceAll('&lt;strong&gt;', '<b>')
    .replaceAll('&lt;/strong&gt;', '</b>')
    .replaceAll('&lt;i&gt;', '<i>')
    .replaceAll('&lt;/i&gt;', '</i>')
    .replaceAll('&lt;br&gt;', '<br>')
    .replaceAll('&lt;br/&gt;', '<br>')
    .replaceAll('&lt;br /&gt;', '<br>');
}

function renderBox(title: string, bodyHtml: string, extraClass = ''): string {
  return `
    <section class="box ${extraClass}">
      <div class="box-title"><span>${escapeHtml(title)}</span></div>
      <div class="box-body">${bodyHtml}</div>
    </section>
  `;
}

function renderMetaTable(vm: CharacterPdfViewModel): string {
  const rows: { label: string; value: string }[] = [
    { label: 'Игрок', value: vm.meta.player },
    { label: 'Имя', value: vm.meta.name },
    { label: 'Раса', value: vm.meta.race },
    { label: 'Профессия', value: vm.meta.profession },
    { label: 'Возраст', value: vm.meta.age },
    { label: 'Определ. навык', value: vm.meta.definingSkill },
  ];

  const body = rows
    .map(
      (r) => `
        <tr>
          <td class="kv-label">${escapeHtml(r.label)}</td>
          <td class="kv-value">${escapeHtml(r.value || '')}</td>
        </tr>
      `,
    )
    .join('');

  return `<table class="kv"><tbody>${body}</tbody></table>`;
}

function renderStatsTable(vm: CharacterPdfViewModel): string {
  const body = vm.stats
    .map(
      (s) => `
        <tr>
          <td class="stat-id">${escapeHtml(s.label)}</td>
          <td class="stat-val">${s.value ?? ''}</td>
        </tr>
      `,
    )
    .join('');

  return `<table class="stats"><tbody>${body}</tbody></table>`;
}

function renderDerivedTable(vm: CharacterPdfViewModel): string {
  if (vm.derived.length === 0) return `<div class="empty">—</div>`;
  const body = vm.derived
    .map(
      (d) => `
        <tr>
          <td class="kv-label">${escapeHtml(d.label)}</td>
          <td class="kv-value">${escapeHtml(d.value)}</td>
        </tr>
      `,
    )
    .join('');
  return `<table class="kv"><tbody>${body}</tbody></table>`;
}

function renderWeaponsTable(vm: CharacterPdfViewModel): string {
  const rows = vm.weapons.length > 0 ? vm.weapons : new Array(4).fill(null).map(() => null);

  const body = rows
    .map((w) => {
      if (!w) {
        return `<tr><td class="fill">&nbsp;</td><td class="fill"></td><td class="fill"></td><td class="fill"></td><td class="fill"></td><td class="fill"></td></tr>`;
      }
      return `
        <tr>
          <td>${escapeHtml(w.name)}</td>
          <td class="t-right">${escapeHtml(w.dmg)}</td>
          <td class="t-right">${escapeHtml(w.reliability)}</td>
          <td class="t-right">${escapeHtml(w.hands)}</td>
          <td class="t-center">${escapeHtml(w.concealment)}</td>
          <td class="t-right">${escapeHtml(w.weight)}</td>
        </tr>
      `;
    })
    .join('');

  return `
    <table class="grid-table">
      <thead>
        <tr>
          <th>Название</th>
          <th class="th-narrow">Урон</th>
          <th class="th-narrow">Прочн</th>
          <th class="th-narrow">Хват</th>
          <th class="th-narrow">Скрыт</th>
          <th class="th-narrow">Вес</th>
        </tr>
      </thead>
      <tbody>${body}</tbody>
    </table>
  `;
}

function renderArmorTable(vm: CharacterPdfViewModel): string {
  const rows = vm.armor.length > 0 ? vm.armor : new Array(4).fill(null).map(() => null);

  const body = rows
    .map((a) => {
      if (!a) {
        return `<tr><td class="fill">&nbsp;</td><td class="fill"></td><td class="fill"></td><td class="fill"></td></tr>`;
      }
      return `
        <tr>
          <td>${escapeHtml(a.name)}</td>
          <td class="t-right">${escapeHtml(a.sp)}</td>
          <td class="t-right">${escapeHtml(a.penalty)}</td>
          <td class="t-right">${escapeHtml(a.weight)}</td>
        </tr>
      `;
    })
    .join('');

  return `
    <table class="grid-table">
      <thead>
        <tr>
          <th>Название</th>
          <th class="th-narrow">SP</th>
          <th class="th-narrow">ПБ</th>
          <th class="th-narrow">Вес</th>
        </tr>
      </thead>
      <tbody>${body}</tbody>
    </table>
  `;
}

function renderSkillBox(skillGroup: CharacterPdfViewModel['skillsByStat'][number]): string {
  const rows = skillGroup.rows.length > 0 ? skillGroup.rows : new Array(8).fill(null).map(() => null);

  const body = rows
    .map((row) => {
      if (!row) return `<tr><td class="fill">&nbsp;</td><td class="fill"></td></tr>`;

      const marker = row.isInitial ? `<span class="mark">*</span>` : '';
      const difficult = row.isDifficult ? `<span class="diff">D</span>` : '';

      return `
        <tr>
          <td class="skill-name">${escapeHtml(row.name)} ${marker}${difficult}</td>
          <td class="skill-val">${row.value ?? ''}</td>
        </tr>
      `;
    })
    .join('');

  return renderBox(skillGroup.title, `<table class="skills"><tbody>${body}</tbody></table>`, 'box-skill');
}

function renderGearTable(vm: CharacterPdfViewModel): string {
  const rows = vm.gear.length > 0 ? vm.gear : new Array(12).fill(null).map(() => null);
  const body = rows
    .map((g) => {
      if (!g) return `<tr><td class="fill">&nbsp;</td><td class="fill"></td><td class="fill"></td><td class="fill"></td></tr>`;
      return `
        <tr>
          <td>${escapeHtml(g.name)}</td>
          <td>${richText(g.notes || '')}</td>
          <td class="t-right">${escapeHtml(g.weight || '')}</td>
          <td class="t-right">${escapeHtml(g.qty || '')}</td>
        </tr>
      `;
    })
    .join('');

  return `
    <table class="grid-table">
      <thead>
        <tr>
          <th>Название</th>
          <th>Описание</th>
          <th class="th-narrow">Вес</th>
          <th class="th-narrow">Кол-во</th>
        </tr>
      </thead>
      <tbody>${body}</tbody>
    </table>
  `;
}

function renderPerks(vm: CharacterPdfViewModel): string {
  if (vm.perks.length === 0) return `<div class="empty">—</div>`;
  return `<ul class="bullets">${vm.perks.map((p) => `<li>${richText(p)}</li>`).join('')}</ul>`;
}

function renderLoreNotes(vm: CharacterPdfViewModel): string {
  if (vm.loreNotes.length === 0) return `<div class="empty">—</div>`;
  const body = vm.loreNotes
    .map(
      (r) =>
        `<div class="note-row"><span class="note-k">${escapeHtml(r.label)}:</span> <span class="note-v">${richText(
          r.value,
        )}</span></div>`,
    )
    .join('');
  return `<div class="notes">${body}</div>`;
}

function renderReputation(vm: CharacterPdfViewModel): string {
  const rows = vm.reputation.length > 0 ? vm.reputation : new Array(4).fill(null).map(() => null);
  const body = rows
    .map((r) => {
      if (!r) return `<tr><td class="fill">&nbsp;</td><td class="fill"></td><td class="fill"></td></tr>`;
      return `
        <tr>
          <td>${escapeHtml(r.groupName)}</td>
          <td class="t-right">${r.status ?? ''}</td>
          <td class="t-center">${r.isFeared ? '✓' : ''}</td>
        </tr>
      `;
    })
    .join('');

  return `
    <table class="grid-table">
      <thead>
        <tr>
          <th>Область</th>
          <th class="th-narrow">Ранг</th>
          <th class="th-narrow">Страх</th>
        </tr>
      </thead>
      <tbody>${body}</tbody>
    </table>
  `;
}

function renderCharacteristics(vm: CharacterPdfViewModel): string {
  const rows = vm.characteristics.length > 0 ? vm.characteristics : new Array(6).fill(null).map(() => null);
  const body = rows
    .map((r) => {
      if (!r) return `<tr><td class="fill">&nbsp;</td><td class="fill"></td></tr>`;
      return `<tr><td>${escapeHtml(r.label)}</td><td>${escapeHtml(r.value)}</td></tr>`;
    })
    .join('');

  return `<table class="grid-table"><tbody>${body}</tbody></table>`;
}

function renderValues(vm: CharacterPdfViewModel): string {
  if (vm.values.length === 0) return `<div class="empty">—</div>`;
  const body = vm.values
    .map((r) => `<div class="note-row"><span class="note-k">${escapeHtml(r.label)}:</span> <span class="note-v">${escapeHtml(r.value)}</span></div>`)
    .join('');
  return `<div class="notes">${body}</div>`;
}

function renderLifeEvents(vm: CharacterPdfViewModel): string {
  const rows = vm.lifeEvents.length > 0 ? vm.lifeEvents : new Array(8).fill(null).map(() => null);
  const body = rows
    .map((e) => {
      if (!e) return `<tr><td class="fill">&nbsp;</td><td class="fill"></td></tr>`;
      const left = [e.timePeriod, e.eventType].filter(Boolean).join(' • ');
      return `<tr><td>${escapeHtml(left)}</td><td>${richText(e.description)}</td></tr>`;
    })
    .join('');

  return `
    <table class="grid-table">
      <thead>
        <tr>
          <th class="th-medium">Год</th>
          <th>Событие</th>
        </tr>
      </thead>
      <tbody>${body}</tbody>
    </table>
  `;
}

export function renderCharacterHtml(vm: CharacterPdfViewModel): string {
  const vigor = vm.stats.find((s) => s.id === 'vigor')?.value ?? null;
  const totalWeightText = vm.totalWeight !== null ? vm.totalWeight.toFixed(1) : '';

  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${escapeHtml(vm.meta.name)} — Witcher Character Sheet</title>
    <style>
      @page { size: A4; margin: 0; }
      * { box-sizing: border-box; }
      html, body { padding: 0; margin: 0; }
      body {
        font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial;
        color: #111827;
        background: white;
        font-size: 11px;
        line-height: 1.25;
      }

      .page {
        width: 210mm;
        min-height: 297mm;
        padding: 6mm;
      }
      .page + .page { page-break-before: always; }

      .box {
        border: 1.5px solid #111827;
        background: #fff;
        break-inside: avoid;
        page-break-inside: avoid;
      }
      .box-title {
        padding: 3px 6px;
        border-bottom: 1.5px solid #111827;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        font-size: 10px;
        font-weight: 800;
        text-align: center;
        background: #f3f4f6;
      }
      .box-body { padding: 6px; }

      .grid-top { display: grid; grid-template-columns: 43% 18% 39%; gap: 6px; }
      .right-col { display: grid; grid-template-rows: auto 1fr auto; gap: 6px; }
      .portrait { height: 105px; display: flex; align-items: center; justify-content: center; color: #9ca3af; font-style: italic; }
      .bars { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; }

      .kv, .stats, .skills, .grid-table { width: 100%; border-collapse: collapse; table-layout: fixed; }
      .kv td { padding: 3px 4px; border-bottom: 1px solid #111827; vertical-align: top; }
      .kv tr:last-child td { border-bottom: 0; }
      .kv-label { width: 48%; font-weight: 700; }
      .kv-value { width: 52%; }

      .stats td { padding: 2px 4px; border-bottom: 1px solid #111827; }
      .stats tr:last-child td { border-bottom: 0; }
      .stat-id { width: 52%; font-weight: 800; text-transform: uppercase; }
      .stat-val { width: 48%; text-align: right; font-variant-numeric: tabular-nums; }

      .grid-mid { display: grid; grid-template-columns: 68% 32%; gap: 6px; margin-top: 6px; }
      .skills-grid { margin-top: 6px; display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px; }

      .skills td { padding: 2px 4px; border-bottom: 1px solid #111827; }
      .skills tr:last-child td { border-bottom: 0; }
      .skill-name { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .skill-val { width: 32px; text-align: right; font-variant-numeric: tabular-nums; }
      .mark { font-weight: 900; margin-left: 2px; }
      .diff { font-size: 9px; border: 1px solid #111827; padding: 0 3px; margin-left: 4px; }

      .grid-table th, .grid-table td { border: 1px solid #111827; padding: 3px 4px; vertical-align: top; }
      .grid-table thead th { background: #f3f4f6; font-size: 10px; text-transform: uppercase; letter-spacing: 0.06em; }
      .th-narrow { width: 38px; }
      .th-medium { width: 80px; }
      .t-right { text-align: right; font-variant-numeric: tabular-nums; }
      .t-center { text-align: center; }

      .empty { color: #9ca3af; font-style: italic; }
      .fill { height: 14px; }

      .bullets { margin: 0; padding-left: 16px; }
      .bullets li { margin: 2px 0; }

      .notes { display: grid; gap: 3px; }
      .note-k { font-weight: 800; }

      .money { font-size: 20px; font-weight: 900; text-align: center; padding: 10px 0; }

      .page2 { display: grid; grid-template-rows: auto 1fr auto; gap: 6px; }
      .page2-top { display: grid; grid-template-columns: 33% 33% 34%; gap: 6px; }
      .page2-mid { display: grid; grid-template-columns: 20% 55% 25%; gap: 6px; }
      .page2-side { display: grid; grid-template-rows: auto auto auto; gap: 6px; }
      .page2-bottom { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; }

      .page3-top { display: grid; grid-template-columns: 65% 35%; gap: 6px; }
      .page3-right { display: grid; grid-template-rows: auto auto auto; gap: 6px; }
    </style>
  </head>
  <body>
    <div class="page">
      <div class="grid-top">
        ${renderBox('Персонаж', renderMetaTable(vm))}
        ${renderBox('Характеристики', renderStatsTable(vm))}
        <div class="right-col">
          ${renderBox('Производные', renderDerivedTable(vm))}
          ${renderBox('Портрет', `<div class="portrait">Портрет</div>`)}
          <div class="bars">
            ${renderBox('MAX HP', `<div class="money">${vm.hpMax ?? ''}</div>`)}
            ${renderBox('MAX STAM', `<div class="money">${vm.staMax ?? ''}</div>`)}
          </div>
        </div>
      </div>

      <div class="grid-mid">
        ${renderBox('Оружие', renderWeaponsTable(vm))}
        ${renderBox('Броня', renderArmorTable(vm))}
      </div>

      <div class="skills-grid">
        ${vm.skillsByStat.filter((g) => g.statId !== 'OTHER').map(renderSkillBox).join('')}
        ${renderBox('Перк/Таланты', renderPerks(vm))}
        ${renderBox('Заметки', renderLoreNotes(vm))}
      </div>
    </div>

    <div class="page page2">
      <div class="page2-top">
        ${renderBox('Очки улучшения', `<div class="empty">—</div>`)}
        ${renderBox('Репутация', renderReputation(vm))}
        ${renderBox('Характер', renderCharacteristics(vm) + `<div style="margin-top:6px">${renderValues(vm)}</div>`)}
      </div>

      <div class="page2-mid">
        <div class="page2-side">
          ${renderBox(
            'Щит',
            `
              <table class="grid-table">
                <thead><tr><th>УРН</th><th class="th-narrow">ПБ</th></tr></thead>
                <tbody>
                  ${new Array(6)
                    .fill(null)
                    .map(() => `<tr><td class="fill">&nbsp;</td><td class="fill"></td></tr>`)
                    .join('')}
                </tbody>
              </table>
            `,
          )}
          ${renderBox(
            'Компоненты',
            `
              <table class="grid-table">
                <thead><tr><th>Название</th><th class="th-narrow">Вес</th></tr></thead>
                <tbody>
                  ${new Array(10)
                    .fill(null)
                    .map(() => `<tr><td class="fill">&nbsp;</td><td class="fill"></td></tr>`)
                    .join('')}
                </tbody>
              </table>
            `,
          )}
          ${renderBox(
            'Общий вес',
            `
              <div class="notes">
                <div><span class="note-k">Итого:</span> ${escapeHtml(totalWeightText)}</div>
                <div><span class="note-k">ENC:</span> ${escapeHtml(vm.derived.find((d) => d.id === 'ENC')?.value ?? '')}</div>
              </div>
            `,
          )}
        </div>

        ${renderBox('Рюкзак / Инвентарь', renderGearTable(vm))}

        ${renderBox('Жизненный путь', renderLifeEvents(vm))}
      </div>

      <div class="page2-bottom">
        ${renderBox(
          'Травмы',
          `
            <table class="grid-table">
              <thead><tr><th>Name</th><th>Effect</th></tr></thead>
              <tbody>
                ${new Array(8).fill(null).map(() => `<tr><td class="fill">&nbsp;</td><td class="fill"></td></tr>`).join('')}
              </tbody>
            </table>
          `,
        )}
        ${renderBox(
          'Квестовые предметы',
          `
            <table class="grid-table">
              <thead><tr><th>Название</th><th class="th-narrow">Кол-во</th></tr></thead>
              <tbody>
                ${new Array(8).fill(null).map(() => `<tr><td class="fill">&nbsp;</td><td class="fill"></td></tr>`).join('')}
              </tbody>
            </table>
          `,
        )}
      </div>

      <div style="display:grid; grid-template-columns: 65% 35%; gap: 6px;">
        ${renderBox(
          'Проф. ветки / умения',
          vm.professionalBranches.length || vm.professionalAbilities.length
            ? `<div>
                ${vm.professionalBranches.length ? `<div><b>Ветки:</b><br>${vm.professionalBranches.map(escapeHtml).join('<br>')}</div>` : ''}
                ${
                  vm.professionalAbilities.length
                    ? `<div style="margin-top:6px"><b>Умения:</b><br>${vm.professionalAbilities
                        .map((a) => escapeHtml(a.name))
                        .join('<br>')}</div>`
                    : ''
                }
              </div>`
            : `<div class="empty">—</div>`,
        )}
        ${renderBox(
          'Деньги',
          `
            <table class="grid-table">
              <thead><tr><th>Орэны</th><th>Флорены</th><th>Реданские кроны</th></tr></thead>
              <tbody><tr><td class="fill"></td><td class="fill"></td><td class="t-right">${escapeHtml(String(vm.moneyCrowns ?? ''))}</td></tr></tbody>
            </table>
          `,
        )}
      </div>
    </div>

    <div class="page">
      <div class="page3-top">
        ${renderBox(
          'Заклинания / Инвокации / Знаки',
          `
            <table class="grid-table">
              <thead>
                <tr>
                  <th>Название</th>
                  <th class="th-narrow">Цена</th>
                  <th>Эффект</th>
                  <th class="th-narrow">ДИС</th>
                  <th class="th-narrow">Длит.</th>
                </tr>
              </thead>
              <tbody>
                ${new Array(18)
                  .fill(null)
                  .map(
                    () =>
                      `<tr><td class="fill">&nbsp;</td><td class="fill"></td><td class="fill"></td><td class="fill"></td><td class="fill"></td></tr>`,
                  )
                  .join('')}
              </tbody>
            </table>
          `,
        )}
        <div class="page3-right">
          ${renderBox(
            'Энергия / Выносливость',
            `<div class="notes">
              <div><span class="note-k">VIG:</span> ${vigor ?? ''}</div>
              <div><span class="note-k">Текущая:</span> </div>
              <div><span class="note-k">Потрачено:</span> </div>
            </div>`,
          )}
          ${renderBox('Фокус', `<div style="height:110px"></div>`)}
          ${renderBox(
            'Порчи',
            `
              <table class="grid-table">
                <thead><tr><th>Name</th><th class="th-narrow">Cost</th><th>Effect</th></tr></thead>
                <tbody>${new Array(8)
                  .fill(null)
                  .map(() => `<tr><td class="fill">&nbsp;</td><td class="fill"></td><td class="fill"></td></tr>`)
                  .join('')}</tbody>
              </table>
            `,
          )}
        </div>
      </div>

      ${renderBox(
        'Ритуалы',
        `
          <table class="grid-table">
            <thead>
              <tr>
                <th>Name</th>
                <th class="th-narrow">Cost</th>
                <th>Effect</th>
                <th class="th-narrow">Время</th>
                <th class="th-narrow">Сл</th>
                <th class="th-narrow">Длит</th>
                <th>Компоненты</th>
              </tr>
            </thead>
            <tbody>
              ${new Array(10)
                .fill(null)
                .map(
                  () =>
                    `<tr><td class="fill">&nbsp;</td><td class="fill"></td><td class="fill"></td><td class="fill"></td><td class="fill"></td><td class="fill"></td><td class="fill"></td></tr>`,
                )
                .join('')}
            </tbody>
          </table>
        `,
      )}
    </div>
  </body>
</html>`;
}
