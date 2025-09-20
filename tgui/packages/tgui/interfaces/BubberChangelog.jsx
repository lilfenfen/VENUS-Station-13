import dateformat from 'dateformat';
import yaml from 'js-yaml';
import { useEffect, useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Icon,
  Image,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Window } from '../layouts';

// --- ICON MAP ---
const icons = {
  add: { icon: 'check-circle', color: 'green' },
  admin: { icon: 'user-shield', color: 'purple' },
  balance: { icon: 'balance-scale-right', color: 'yellow' },
  bugfix: { icon: 'bug', color: 'green' },
  code_imp: { icon: 'code', color: 'green' },
  config: { icon: 'cogs', color: 'purple' },
  expansion: { icon: 'check-circle', color: 'green' },
  experiment: { icon: 'radiation', color: 'yellow' },
  image: { icon: 'image', color: 'green' },
  imageadd: { icon: 'tg-image-plus', color: 'green' },
  imagedel: { icon: 'tg-image-minus', color: 'red' },
  qol: { icon: 'hand-holding-heart', color: 'green' },
  refactor: { icon: 'tools', color: 'green' },
  rscadd: { icon: 'check-circle', color: 'green' },
  rscdel: { icon: 'times-circle', color: 'red' },
  server: { icon: 'server', color: 'purple' },
  sound: { icon: 'volume-high', color: 'green' },
  soundadd: { icon: 'tg-sound-plus', color: 'green' },
  sounddel: { icon: 'tg-sound-minus', color: 'red' },
  spellcheck: { icon: 'spell-check', color: 'green' },
  map: { icon: 'map', color: 'green' },
  tgs: { icon: 'toolbox', color: 'purple' },
  tweak: { icon: 'wrench', color: 'green' },
  unknown: { icon: 'info-circle', color: 'label' },
  wip: { icon: 'hammer', color: 'orange' },
};

// --- SOURCE MAP ---
const CHANGELOG_SOURCES = {
  tg: { icon: 'tg_16.png', name: 'TG Station' },
  bubber: { icon: 'bubber_16.png', name: 'Bubberstation' },
  splurt: { icon: 'splurt_16.png', name: 'Splurt' },
  venus: { icon: 'venus_16.png', name: 'VENUS' },
  veilbreak: { icon: 'veilbreak_16.png', name: 'Veilbreak Frontier' },
};

// --- DATE PICKER ---
const DateDropdown = ({
  dates,
  selectedDate,
  setSelectedDate,
  selectedDateIndex,
  setSelectedDateIndex,
}) => {
  if (!dates || dates.length === 0) return null;

  const handleSelect = (index) => {
    setSelectedDateIndex(index);
    setSelectedDate(dates[index]);
    window.scrollTo(
      0,
      document.body.scrollHeight || document.documentElement.scrollHeight,
    );
  };

  return (
    <Stack mb={1}>
      <Stack.Item>
        <Button
          className="Changelog__Button"
          disabled={selectedDateIndex <= 0}
          icon="chevron-left"
          onClick={() => handleSelect(selectedDateIndex - 1)}
        />
      </Stack.Item>
      <Stack.Item>
        <Dropdown
          autoScroll={false}
          options={dates}
          onSelected={(value) => handleSelect(dates.indexOf(value))}
          selected={selectedDate}
          width="150px"
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          className="Changelog__Button"
          disabled={selectedDateIndex >= dates.length - 1}
          icon="chevron-right"
          onClick={() => handleSelect(selectedDateIndex + 1)}
        />
      </Stack.Item>
    </Stack>
  );
};

// --- SINGLE ENTRY ---
const ChangelogEntry = ({ author, changes, source }) => {
  const { icon, name } = CHANGELOG_SOURCES[source] || CHANGELOG_SOURCES.tg;

  return (
    <Stack.Item mb={-1} pb={1} key={author}>
      <Box>
        <h4>
          <Image verticalAlign="bottom" src={resolveAsset(icon)} /> {name}:{' '}
          {author} changed:
        </h4>
      </Box>
      <Box ml={3} mt={-0.2}>
        <Table>
          {changes.map((change, idx) => {
            const type = Object.keys(change)[0];
            return (
              <Table.Row key={idx}>
                <Table.Cell
                  className={classes([
                    'Changelog__Cell',
                    'Changelog__Cell--Icon',
                  ])}
                >
                  <Icon
                    color={icons[type]?.color || icons.unknown.color}
                    name={icons[type]?.icon || icons.unknown.icon}
                    verticalAlign="middle"
                  />
                </Table.Cell>
                <Table.Cell className="Changelog__Cell">
                  {change[type]}
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
      </Box>
    </Stack.Item>
  );
};

// --- LIST OF ENTRIES ---
const ChangelogList = ({ contents }) => {
  const combinedDates = Object.keys(contents || {}).reduce((acc, source) => {
    Object.keys(contents[source] || {}).forEach((date) => {
      acc[date] = acc[date] || {};
      acc[date][source] = contents[source][date];
    });
    return acc;
  }, {});

  if (Object.keys(combinedDates).length < 1) {
    return <p>No changelog data available.</p>;
  }

  return Object.keys(combinedDates)
    .sort()
    .reverse()
    .map((date) => {
      const parsed = new Date(date);
      const formatted = isNaN(parsed)
        ? date
        : dateformat(parsed, 'd mmmm yyyy', true);

      return (
        <Section key={date} title={formatted} pb={1}>
          <Box ml={3}>
            {Object.entries(combinedDates[date]).map(([source, authors]) => (
              <Section key={source} mb={-2}>
                {authors ? (
                  Object.entries(authors).map(([author, changes]) => (
                    <ChangelogEntry
                      key={author}
                      author={author}
                      changes={changes}
                      source={source}
                    />
                  ))
                ) : (
                  <i>No entries from {source}.</i>
                )}
              </Section>
            ))}
          </Box>
        </Section>
      );
    });
};

// --- MAIN COMPONENT ---
export const BubberChangelog = () => {
  const { data, act } = useBackend();
  const { dates = [] } = data;

  const [contents, setContents] = useState({});
  const [selectedDateIndex, setSelectedDateIndex] = useState(
    dates.length ? 0 : -1,
  );
  const [selectedDate, setSelectedDate] = useState(dates[0] ?? null);

  useEffect(() => {
    if (!selectedDate) return;
    setContents({});
    getData(selectedDate);
  }, [selectedDate]);

  const getData = async (date, attempt = 1) => {
    const maxAttempts = 6;
    if (attempt > maxAttempts) {
      setContents({
        error: `Failed to load data after ${maxAttempts} attempts.`,
      });
      return;
    }

    act('get_month', { date });

    try {
      const results = await Promise.allSettled(
        Object.keys(CHANGELOG_SOURCES).map((source) => {
          const file =
            source === 'tg' ? `${date}.yml` : `${source}_${date}.yml`;
          return fetch(resolveAsset(file));
        }),
      );

      let hadRetryableErrors = false;

      await Promise.all(
        results.map(async (res, idx) => {
          const source = Object.keys(CHANGELOG_SOURCES)[idx];
          if (res.status === 'fulfilled') {
            const response = res.value;
            if (response.ok) {
              const text = await response.text();
              const parsed = yaml.load(text, { schema: yaml.CORE_SCHEMA });

              // Normalize into { source: { date: parsed } }
              setContents((prev) => ({
                ...prev,
                [source]: {
                  ...(prev[source] || {}),
                  [date]: parsed || {},
                },
              }));
            } else if (response.status >= 500) {
              hadRetryableErrors = true;
            } else {
              setContents((prev) => ({
                ...prev,
                [source]: {
                  ...(prev[source] || {}),
                  [date]: {},
                },
              }));
            }
          } else {
            hadRetryableErrors = true;
          }
        }),
      );

      if (hadRetryableErrors) {
        const timeout = 50 + attempt * 50;
        setTimeout(() => getData(date, attempt + 1), timeout);
      }
    } catch (err) {
      const timeout = 50 + attempt * 50;
      setTimeout(() => getData(date, attempt + 1), timeout);
    }
  };

  const header = (
    <Section>
      <h1>Veilbreak Frontier</h1>
      <p>
        <b>Thanks to: </b>
        /tg/station 13, Effigy, Stellar Haven, Baystation 12, /vg/station,
        NTstation, CDK Station devs, FacepunchStation, GoonStation devs, the
        original Space Station 13 developers, and the countless others who have
        contributed to the game.
      </p>
      <p>
        Veilbreak Frontier contributors can be found{' '}
        <a href="https://github.com/lilfenfen/Veilbreak-Frontier/people">
          here
        </a>
        , and recent activity{' '}
        <a href="https://github.com/lilfenfen/Veilbreak-Frontier/pulse/monthly">
          here
        </a>
        . Current organization members can be found{' '}
        <a href="https://github.com/orgs/VENUS-Station/people">here</a>, recent
        GitHub contributors{' '}
        <a href="https://github.com/VENUS-Station/V.E.N.U.S-TG/pulse/monthly">
          here
        </a>
        .
      </p>
      <p>
        Or join the Veilbreak Frontier discord{' '}
        <a href="https://discord.gg/ychmq3tZQY">here</a>!
      </p>
      <DateDropdown
        dates={dates}
        selectedDate={selectedDate}
        setSelectedDate={setSelectedDate}
        selectedDateIndex={selectedDateIndex}
        setSelectedDateIndex={setSelectedDateIndex}
      />
    </Section>
  );

  const footer = (
    <Section>
      <DateDropdown
        dates={dates}
        selectedDate={selectedDate}
        setSelectedDate={setSelectedDate}
        selectedDateIndex={selectedDateIndex}
        setSelectedDateIndex={setSelectedDateIndex}
      />
      <h2>Licenses</h2>
      {/* You can drop your license section here */}
    </Section>
  );

  return (
    <Window title="Changelog" width={730} height={700}>
      <Window.Content scrollable>
        {header}
        <ChangelogList contents={contents} />
        {footer}
      </Window.Content>
    </Window>
  );
};
