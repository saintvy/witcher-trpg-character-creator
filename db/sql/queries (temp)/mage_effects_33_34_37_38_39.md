# Эффекты в нодах 33-34 и 37-39

Ниже перечислены только те эффекты, которые сейчас реально вставляются через `INSERT INTO effects`.

## Академия

| Вариант | Эффекты |
|---|---|
| `Академия все варианты, кроме 1-10, 2-8, 4-6, 4-7` | Добавляется запись в `characterRaw.lore.lifeEvents` с типом `Жизнь в академии` и описанием выбранного события |
| `Академия 1-1`, `2-1`, `3-1`, `4-1` | `characterRaw.statistics.vigor.bonus -= 1` |
| `Академия 1-4` | `characterRaw.professional_gear_options.novice_spells_tokens += 1` |
| `Академия 4-9` | `characterRaw.professional_gear_options.novice_spells_tokens += 1` |
| `Академия 3-3` | `characterRaw.professional_gear_options.bomb_formulae_tokens += 1` |
| `Академия 2-3`, `3-5` | В `characterRaw.gear.general_gear` добавляется локализованный предмет `Магическая формула (Подмастерье) / Spell Formulae (Journeyman)` |
| `Академия 4-4` | `characterRaw.skills.common.first_aid.bonus += 2` |
| `Академия 2-5` | `characterRaw.skills.common.monster_lore.bonus += 1` |
| `Академия 4-5` | `characterRaw.skills.common.wilderness_survival.bonus += 2` |
| `Академия 4-8` | `characterRaw.skills.common.monster_lore.bonus += 1` |
| `Академия 3-9` | `characterRaw.skills.common.charisma.bonus += 1` и `characterRaw.skills.common.social_etiquette.bonus += 1` |
| `Академия 2-10` | `characterRaw.skills.common.language_elder_speech.bonus += 2` |
| `Академия 3-10` | `characterRaw.skills.common.disguise.bonus += 1` и в `characterRaw.perks` добавляется перк `Шпионаж / Spycraft` |
| `Академия 1-6` | `characterRaw.money.alchemyIngredientsCrowns += 100` |
| `Академия 1-7` | В `characterRaw.gear.general_gear` добавляется кастомный предмет `Услуга учителя, полученная шантажом / Teacher's Favor Obtained by Blackmail` |
| `Академия 4-10` | В `characterRaw.gear.general_gear` добавляется предмет `T147` (`Фокусирующий амулет`) |
| `Академия 1-2`, `1-3`, `1-9`, `1-10`, `2-2`, `2-3`, `2-4`, `2-6`, `2-8`, `3-6`, `3-8`, `4-3`, `4-6`, `4-7` | `characterRaw.logicFields.last_node_and_answer = "academy life X-Y"` |
| `Академия 4-3` | В `characterRaw.enemies` сразу добавляется готовый враг: `victim=Другая сторона`, `position=Ведьмак`, `cause=Ущерб из-за вашей магии`, `how_far=Он или вы достаточно злы...`, `the_power=Физическая` |

## Академия: детали

| Вариант | Эффекты |
|---|---|
| `Академия любой вариант 1-1..4-10` | `characterRaw.logicFields.flags.academy_life = 1`, если `counters.lifeEventsCounter <= 9`, иначе `2` |
| `Академия 1-7-02..05` | В `characterRaw.lore.diseases_and_curses` добавляется выбранное проклятие |
| `Академия 2-7-01..06` | `characterRaw.money.crowns += 100/200/300/400/500/600` |
| `Академия 3-7-01,03,05,07,09,11,13,15,17,19` | Новый боевой навык: соответствующий `characterRaw.skills.common.<skill>.cur = 2` |
| `Академия 3-7-02,04,06,08,10,12,14,16,18,20` | Уже имеющийся боевой навык: `characterRaw.skills.common.<skill>.cur += 1` |
| `Академия 3-7-01..20` | Дополнительно сохраняется детализированное событие в `characterRaw.lore.lifeEvents` |
| `Академия 4-6-01..23` | Сохраняется детализированное событие в `characterRaw.lore.lifeEvents` |
| `Академия 4-6-01..23` | Если региона ещё нет в массиве, добавляется `characterRaw.social_status[]` со статусом `Equal` |

## Опасность

| Вариант | Эффекты |
|---|---|
| `Опасность 2-1` | `characterRaw.logicFields.last_node_and_answer` выставляется дважды: сначала в `life events 1-2`, затем в `life events 2-1` |
| `Опасность 2-3` | `characterRaw.logicFields.last_node_and_answer = "life events 2-3"` и запускается backend-эффект `make_a_traitor` |
| `Опасность 2-4` | `characterRaw.logicFields.last_node_and_answer = "life events 2-4"` и запускается backend-эффект `kill_a_friend` |
| `Опасность 2-5` | `characterRaw.logicFields.last_node_and_answer = "life events 2-5"` |
| `Опасность 2-9` | `characterRaw.logicFields.last_node_and_answer = "life events 2-9"` |
| `Опасность 4-10` | `characterRaw.logicFields.last_node_and_answer = "life events 4-10"` |

## Опасность: детали

| Вариант | Эффекты |
|---|---|
| `Опасность детали` | Сейчас прямых `effects` нет |
| `Опасность детали 2` | Сейчас прямых `effects` нет |

## Нюанс

- У `Опасность 2-1` сейчас два `set` на один и тот же путь. Практически полезным остаётся последнее значение, то есть `life events 2-1`.
