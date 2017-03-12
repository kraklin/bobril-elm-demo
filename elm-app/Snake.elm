port module Snake exposing (..)

import Html exposing (Html, programWithFlags, text, div, img)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Keyboard exposing (..)
import Time exposing (..)
import Random


main : Program GameTheme Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


port gameOver : Int -> Cmd msg


port setTheme : (GameTheme -> msg) -> Sub msg


type alias Model =
    { snake : Snake
    , direction : Direction
    , state : GameState
    , apple : Maybe Point
    , score : Int
    , speed : Float
    , theme : GameTheme
    }


type GameState
    = NotStarted
    | Started
    | Paused
    | GameOver


pitSize =
    20


squareSize =
    15


maxIndex =
    pitSize - 1


type alias Snake =
    ( Point, List Point )


type alias Point =
    ( Int, Int )


type Direction
    = Up
    | Down
    | Left
    | Right


type alias GameTheme =
    { snakeColor : String
    , appleColor : String
    , backgroundColor : String
    }


init : GameTheme -> ( Model, Cmd Msg )
init theme =
    ( initModel theme, Cmd.none )


initModel : GameTheme -> Model
initModel theme =
    { snake = initSnake
    , direction = Left
    , state = NotStarted
    , apple = Just ( 5, 5 )
    , score = 0
    , speed = 200
    , theme = theme
    }


restartGame : Model -> Model
restartGame model =
    { model
        | snake = initSnake
        , direction = Left
        , state = Started
        , apple = Just ( 5, 5 )
        , score = 0
        , speed = 200
    }


initSnake : Snake
initSnake =
    let
        tail =
            (List.range 1 5) |> List.map (\index -> ( 10 + index, 11 ))

        head =
            ( 10, 11 )
    in
        ( head, tail )


type Msg
    = Move Time
    | KeyboardInput KeyCode
    | SpawnCherry Point
    | SetTheme GameTheme


updateBackground color theme =
    { theme | backgroundColor = color }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Move time ->
            checkAndMove model

        SpawnCherry coords ->
            ( { model | apple = Just coords }, Cmd.none )

        SetTheme newTheme ->
            ( { model | theme = newTheme }, Cmd.none )

        KeyboardInput code ->
            case code of
                27 ->
                    case model.state of
                        Started ->
                            ( { model | state = Paused }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                32 ->
                    case model.state of
                        NotStarted ->
                            ( (restartGame model), Cmd.none )

                        GameOver ->
                            ( (restartGame model), Cmd.none )

                        Paused ->
                            ( { model | state = Started }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                39 ->
                    ( { model | direction = Right }, Cmd.none )

                38 ->
                    ( { model | direction = Up }, Cmd.none )

                37 ->
                    ( { model | direction = Left }, Cmd.none )

                40 ->
                    ( { model | direction = Down }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


checkAndMove : Model -> ( Model, Cmd Msg )
checkAndMove model =
    let
        ( newHead, newTail ) =
            move model.snake model.direction

        ( newHeadX, newHeadY ) =
            newHead

        ( oldHead, oldTail ) =
            model.snake

        isCrashed =
            (newHeadX < 0 || newHeadX > maxIndex || newHeadY < 0 || newHeadY > maxIndex) || (not (newTail |> List.all (\t -> t /= newHead)))

        ateApple =
            case model.apple of
                Just apple ->
                    (newHeadX == (Tuple.first apple) && (Tuple.second apple) == newHeadY)

                Nothing ->
                    False
    in
        if (isCrashed) then
            ( { model | state = GameOver }, gameOver model.score )
        else if ateApple then
            ( { model
                | snake = ( newHead, oldHead :: oldTail )
                , apple = Nothing
                , score = model.score + 1
                , speed =
                    if (model.score % 5 == 0) then
                        model.speed * 0.95
                    else
                        model.speed
              }
            , Random.generate SpawnCherry (Random.pair (Random.int 0 maxIndex) (Random.int 0 maxIndex))
            )
        else
            ( { model | snake = ( newHead, newTail ) }, Cmd.none )


move : Snake -> Direction -> Snake
move snake direction =
    let
        moveHead dir ( x, y ) =
            case dir of
                Left ->
                    ( x - 1, y )

                Right ->
                    ( x + 1, y )

                Up ->
                    ( x, y - 1 )

                Down ->
                    ( x, y + 1 )

        cutTail tail =
            tail |> List.take ((List.length tail) - 1)

        updateSnake dir ( head, tail ) =
            ( (moveHead dir head), head :: cutTail tail )
    in
        snake |> updateSnake direction


view : Model -> Html Msg
view model =
    div []
        [ div [] [ Html.text "Snake" ]
        , svg [ viewBox "0 0 300 300", width "300" ]
            (List.concat
                [ [ rect [ width "300", height "300", fill model.theme.backgroundColor ] [] ]
                , drawScene model
                ]
            )
        , div [] [ Html.text ("Score: " ++ toString model.score) ]
        ]


drawScene : Model -> List (Svg Msg)
drawScene model =
    case model.state of
        NotStarted ->
            [ drawCenteredText "Press Space to Start" ]

        Started ->
            List.concat
                [ drawSnake model.snake model.theme.snakeColor
                , drawApple model.apple model.theme.appleColor
                ]

        Paused ->
            [ drawCenteredText "Paused - Press Space to continue" ]

        GameOver ->
            [ drawCenteredText "Game Over - restart with space" ]


drawCenteredText : String -> Svg Msg
drawCenteredText displayText =
    Svg.text_ [ fill "white", x "150", y "150", alignmentBaseline "central", textAnchor "middle" ] [ Svg.text displayText ]


drawApple : Maybe Point -> String -> List (Svg Msg)
drawApple apple color =
    case apple of
        Just apple ->
            [ drawTile color apple ]

        Nothing ->
            []


drawTile : String -> Point -> Svg Msg
drawTile color ( px, py ) =
    rect
        [ width "15"
        , height "15"
        , x (toString (15 * px))
        , y (toString (15 * py))
        , fill color
        , stroke "#000000"
        ]
        []


drawSnake : Snake -> String -> List (Svg Msg)
drawSnake ( head, tail ) color =
    (drawTile color head)
        :: (tail
                |> List.map (drawTile color)
           )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Started ->
            Sub.batch
                [ Keyboard.downs KeyboardInput
                , Time.every (Time.inMilliseconds model.speed) Move
                , setTheme SetTheme
                ]

        _ ->
            Sub.batch
                [ Keyboard.downs KeyboardInput
                , setTheme SetTheme
                ]
