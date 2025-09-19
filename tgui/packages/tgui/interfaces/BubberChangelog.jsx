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

const CHANGELOG_SOURCES = {
  tg: { icon: 'tg_16.png', name: 'TG Station' },
  bubber: { icon: 'bubber_16.png', name: 'Bubberstation' },
  splurt: { icon: 'splurt_16.png', name: 'Splurt' },
  venus: { icon: 'venus_16.png', name: 'VENUS' },
  veilbreak: { icon: 'veilbreak_16.png', name: 'Veilbreak Frontier' },
};

const DateDropdown = (props) => {
  const {
    dates,
    selectedDate,
    setSelectedDate,
    selectedDateIndex,
    setSelectedDateIndex,
  } = props;

  if (dates.length === 0) return null;

  return (
    <Stack mb={1}>
      <Stack.Item>
        <Button
          className="Changelog__Button"
          disabled={selectedDateIndex === 0}
          icon={'chevron-left'}
          onClick={() => {
            const index = selectedDateIndex - 1;
            setSelectedDateIndex(index);
            setSelectedDate(dates[index]);
            window.scrollTo(
              0,
              document.body.scrollHeight ||
                document.documentElement.scrollHeight,
            );
          }}
        />
      </Stack.Item>
      <Stack.Item>
        <Dropdown
          autoScroll={false}
          options={dates}
          onSelected={(value) => {
            const index = dates.indexOf(value);
            setSelectedDateIndex(index);
            setSelectedDate(value);
            window.scrollTo(
              0,
              document.body.scrollHeight ||
                document.documentElement.scrollHeight,
            );
          }}
          selected={selectedDate}
          width="150px"
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          className="Changelog__Button"
          disabled={selectedDateIndex === dates.length - 1}
          icon={'chevron-right'}
          onClick={() => {
            const index = selectedDateIndex + 1;
            setSelectedDateIndex(index);
            setSelectedDate(dates[index]);
            window.scrollTo(
              0,
              document.body.scrollHeight ||
                document.documentElement.scrollHeight,
            );
          }}
        />
      </Stack.Item>
    </Stack>
  );
};

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
          {changes.map((change) => {
            const changeType = Object.keys(change)[0];
            return (
              <Table.Row key={changeType + change[changeType]}>
                <Table.Cell
                  className={classes([
                    'Changelog__Cell',
                    'Changelog__Cell--Icon',
                  ])}
                >
                  <Icon
                    color={icons[changeType]?.color || icons.unknown.color}
                    name={icons[changeType]?.icon || icons.unknown.icon}
                    verticalAlign="middle"
                  />
                </Table.Cell>
                <Table.Cell className="Changelog__Cell">
                  {change[changeType]}
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
      </Box>
    </Stack.Item>
  );
};

const ChangelogList = ({ contents }) => {
  const combinedDates = Object.keys(contents).reduce((acc, source) => {
    Object.keys(contents[source]).forEach((date) => {
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
    .map((date) => (
      <Section key={date} title={dateformat(date, 'd mmmm yyyy', true)} pb={1}>
        <Box ml={3}>
          {Object.entries(combinedDates[date]).map(([source, authors]) => (
            <Section key={source} mb={-2}>
              {Object.entries(authors).map(([author, changes]) => (
                <ChangelogEntry
                  key={author}
                  author={author}
                  changes={changes}
                  source={source}
                />
              ))}
            </Section>
          ))}
        </Box>
      </Section>
    ));
};

export const BubberChangelog = (props) => {
  const { data } = useBackend();
  const { dates } = data;
  const [contents, setContents] = useState({});
  const [selectedDate, setSelectedDate] = useState(dates[0]);
  const [selectedDateIndex, setSelectedDateIndex] = useState(0);

  useEffect(() => {
    setContents({});
    getData(selectedDate);
  }, [selectedDate]);

  const getData = async (date, attemptNumber = 1) => {
    const maxAttempts = 6;
    if (attemptNumber > maxAttempts) {
      setContents({
        error: `Failed to load data after ${maxAttempts} attempts.`,
      });
      return;
    }

    const { act } = useBackend();
    act('get_month', { date });

    try {
      const results = await Promise.allSettled(
        Object.keys(CHANGELOG_SOURCES).map((source) =>
          fetch(
            resolveAsset(
              source === 'tg' ? `${date}.yml` : `${source}_${date}.yml`,
            ),
          ),
        ),
      );

      const newContents = { ...contents };
      let hasErrors = false;

      await Promise.all(
        results.map(async (result, index) => {
          const source = Object.keys(CHANGELOG_SOURCES)[index];
          if (result.status === 'fulfilled' && result.value.status === 200) {
            const text = await result.value.text();
            newContents[source] = yaml.load(text, { schema: yaml.CORE_SCHEMA });
          } else {
            hasErrors = true;
          }
        }),
      );

      if (hasErrors) {
        const timeout = 50 + attemptNumber * 50;
        setTimeout(() => getData(date, attemptNumber + 1), timeout);
      } else {
        setContents(newContents);
      }
    } catch (error) {
      const timeout = 50 + attemptNumber * 50;
      setTimeout(() => getData(date, attemptNumber + 1), timeout);
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
        .{' Veilbreak Frontier contributors can be found '}
        <a href="https://github.com/lilfenfen/Veilbreak-Frontier/people">
          here
        </a>
        {', and recent activity '}
        <a href="https://github.com/lilfenfen/Veilbreak-Frontier/pulse/monthly">
          here
        </a>
        {'Current organization members can be found '}
        <a href="https://github.com/orgs/VENUS-Station/people">here</a>
        {', recent GitHub contributors can be found '}
        <a href="https://github.com/VENUS-Station/V.E.N.U.S-TG/pulse/monthly">
          here
        </a>
        .
      </p>
      <p>
        {' or Veilbreak Frontier discord '}
        <a href="https://discord.gg/VfR56x7m">here</a>!
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
      {Object.entries({
        'V.E.N.U.S Station 13': {
          license: 'GNU AGPL v3',
          licenseUrl: 'https://www.gnu.org/licenses/agpl-3.0.html',
          link: 'https://github.com/VENUS-Station/V.E.N.U.S-TG/blob/master/LICENSE',
          assets: true,
        },
        'Veilbreak Frontier': {
          license: 'GNU AGPL v3',
          licenseUrl: 'https://www.gnu.org/licenses/agpl-3.0.html',
          link: 'https://github.com/lilfenfen/Veilbreak-Frontier/blob/master/LICENSE',
          assets: true,
        },
        TGS: {
          license: 'MIT',
          special: true,
        },
        '/tg/station 13': {
          license: 'GNU AGPL v3',
          licenseUrl: 'https://www.gnu.org/licenses/agpl-3.0.html',
          link: 'https://github.com/tgstation/tgstation/blob/master/LICENSE',
          assets: true,
          cutoff: true,
        },
        'Goonstation SS13': {
          credits: true,
          license: 'CC BY-NC-SA 3.0',
          licenseUrl: 'https://creativecommons.org/licenses/by-nc-sa/3.0/',
        },
      }).map(([name, config]) => (
        <Section key={name} title={name}>
          {config.credits ? (
            <>
              <p>
                <b>Coders: </b>Stuntwaffle, Showtime, Pantaloons, Nannek,
                Keelin, Exadv1, hobnob, Justicefries, 0staf, sniperchance,
                AngriestIBM, BrianOBlivion
              </p>
              <p>
                <b>Spriters: </b>Supernorn, Haruhi, Stuntwaffle, Pantaloons,
                Rho, SynthOrange, I Said No
              </p>
            </>
          ) : config.special ? (
            <>
              <p>
                The TGS DMAPI API is licensed as a subproject under the MIT
                license.
              </p>
              <p>
                {' See the footer of '}
                <a
                  href={
                    'https://github.com/tgstation/tgstation/blob/master/code/__DEFINES/tgs.dm'
                  }
                >
                  code/__DEFINES/tgs.dm
                </a>
                {' and '}
                <a
                  href={
                    'https://github.com/tgstation/tgstation/blob/master/code/modules/tgs/LICENSE'
                  }
                >
                  code/modules/tgs/LICENSE
                </a>
                {' for the MIT license.'}
              </p>
            </>
          ) : (
            <>
              {config.cutoff && (
                <p>
                  {'All code after '}
                  <a
                    href={
                      'https://github.com/tgstation/tgstation/commit/333c566b88108de218d882840e61928a9b759d8f'
                    }
                  >
                    commit 333c566b88108de218d882840e61928a9b759d8f
                  </a>
                  {' is licensed under '}
                  <a href={config.licenseUrl}>{config.license}</a>.
                </p>
              )}
              <p>
                {!config.cutoff && `All code is licensed under `}
                <a href={config.licenseUrl}>{config.license}</a>.{' See '}
                <a href={config.link}>LICENSE</a>
                {config.cutoff && (
                  <>
                    {' and '}
                    <a href="https://github.com/tgstation/tgstation/blob/master/GPLv3.txt">
                      GPLv3.txt
                    </a>
                    {' for more details.'}
                  </>
                )}
              </p>
              {config.assets && (
                <p>
                  {'All assets including icons and sound are under a '}
                  <a href="https://creativecommons.org/licenses/by-sa/3.0/">
                    Creative Commons 3.0 BY-SA license
                  </a>
                  {' unless otherwise indicated.'}
                </p>
              )}
            </>
          )}
        </Section>
      ))}
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
