import * as b from 'bobril';
import * as m from 'bobril-m';
import * as ElmComponent from 'bobril-elm-component';
import * as Theme from './themes';

//Elm code compiled with > elm make Snake.elm -o snake.js
b.asset('elm-app/snake.js');
declare var Elm: any;

let gamesPlayed = [];
let playerName = b.propi('');

let setTheme: ElmComponent.SendFn<Theme.ITheme>;

let setupPorts = (elmPorts) => {
    setTheme = elmPorts.setTheme.send;

    elmPorts.gameOver.subscribe((score) => {
        gamesPlayed.push({ name: (playerName() === '') ? 'Anonymous' : playerName(), score: score });
        b.invalidate();
    });
};

b.init(() => {
    return m.Paper({ style: { width: 700, marginLeft: 'auto', marginRight: 'auto', padding: '1em' } }, [
        {tag: 'h1', children: 'Bobril with Elm component'},
        {tag: 'p', children: 'This is a small example of using Elm app as component inside Bobril framework.'},
        m.Paper({zDepth: 3, style: {width: 350, padding: '1em', display: 'inline-block', verticalAlign: 'top'}}, [
            m.TextField({value: playerName, labelText: 'Player Name'}),

            //here comes the magic of using ElmComponent to register elm app. 
            ElmComponent.create({src: Elm.Snake, flags: Theme.rgbTheme, setupPorts: setupPorts })
        ]),
        m.Paper({zDepth: 3, style: {width: 300, padding: '1em', marginLeft: '1em', display: 'inline-block', verticalAlign: 'top'}}, [
                m.List({}, [
                    m.Subheader({}, 'Select Game Theme'),
                m.ListItem({ primaryText: 'RGB', action: () => setTheme(Theme.rgbTheme) }),
                m.ListItem({ primaryText: 'Dark', action: () => setTheme(Theme.darkTheme) })
            ]),
            m.Divider(),
            m.List({}, [
                m.Subheader({}, 'TOP 3 Players Score'),
                ...gamesPlayed.sort((a, b) => {
                    return (a.score < b.score) ? 1 : (a.score > b.score) ? -1 : 0;
                })
                .slice(0, 3)
                .map((game) => {
                    return m.ListItem({primaryText: `Score: ${game.score}`, secondaryText: game.name});
                })
            ])
        ]),
        {tag: 'h4', children: 'How to play'},
        {tag: 'p', children: 'Use Arrows to control the Snake. You can pause the game with Esc and start again with Space. Try not to run into the wall or snake\'s tail.'},
   ]);
});