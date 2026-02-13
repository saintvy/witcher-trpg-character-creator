import assert from 'node:assert/strict';
import { mapCharacterJsonToPage4Vm } from '../src/pdf/pages/viewModelPage4.js';

const i18n = {
  lang: 'ru',
  source: {
    magicSpellsTitle: '',
    magicSignsTitle: '',
    magicHexesTitle: '',
    magicRitualsTitle: '',
    invocationsPriestTitle: '',
    invocationsDruidTitle: 'Инвокации друида',
    magicGiftsTitle: '',
  },
  effects: { title: '' },
  column: {
    name: '',
    element: '',
    level: '',
    group: '',
    staminaCast: '',
    staminaKeeping: '',
    damage: '',
    distance: '',
    zoneSize: '',
    form: '',
    preparingTime: '',
    dc: '',
    effectTime: '',
  },
  gifts: {
    colName: '',
    colGroup: '',
    colSl: '',
    colVigor: '',
    colCost: '',
    costAction: '',
    costFullAction: '',
  },
} as const;

function runCase(profession: string, invocationKey: 'druid' | 'priest') {
  const character = {
    profession,
    statistics: { vigor: { cur: 2 } },
    gear: {
      magic: {
        invocations: {
          [invocationKey]: [
            { invocation_name: 'Кипящая кровь', stamina_cast: '3', distance: '8', form: 'Прямая', effect: '...' },
            { invocation_name: 'Паутина корней', stamina_cast: '2', stamina_keeping: '1', distance: '10', form: 'Прямая', effect: '...' },
          ],
        },
      },
    },
  };

  const vm = mapCharacterJsonToPage4Vm(character, { i18n });
  assert.equal(vm.showInvocations, true);
  assert.equal(vm.invocations.length, 2);
  if (invocationKey === 'druid') {
    assert.equal(vm.invocationsTitle, 'Инвокации друида');
    assert.equal(vm.invocationsBoxClass, 'magic4-invocations-druid-box');
  } else {
    assert.equal(vm.invocationsTitle, '');
    assert.equal(vm.invocationsBoxClass, 'magic4-invocations-box');
  }
  assert.deepEqual(
    vm.invocations.map((x) => x.name),
    ['Кипящая кровь', 'Паутина корней'],
  );
}

runCase('Друид', 'druid');
runCase('Жрец', 'priest');

console.log('[smoke] page4 invocations OK');
