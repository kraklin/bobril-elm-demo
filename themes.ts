export interface ITheme {
    snakeColor: string;
    appleColor: string;
    backgroundColor: string;
}

export let rgbTheme: ITheme = {
   snakeColor: '#00ff00',
   appleColor: '#ff0000',
   backgroundColor: '#0000ff'
};

export let darkTheme: ITheme = {
   snakeColor: '#00ffff',
   appleColor: '#ffff00',
   backgroundColor: '#222222' 
};