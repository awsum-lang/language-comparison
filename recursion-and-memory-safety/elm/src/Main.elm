port module Main exposing (main)

{-| This demo program builds an immutable tree of depth 500\_000, mirrors it 500
times (causing heavy allocation pressure), and displays the deepest value on
the left path.

Elm outcome: `RangeError: Maximum call stack size exceeded` inside `mirror` on
the very first call. `Node (mirror r) v (mirror l)` is multi-child non-tail
self-recursion — Elm's TCO emits a `while` loop only for self-recursive _tail_
calls, so the depth-500\_000 V-tree exhausts the JS engine's call stack before
any output is produced. `deepestLeftA/B/C` would similarly overflow if reached,
because Elm doesn't optimize mutual tail recursion either.

-}

import Platform exposing (Program)


port stdout : String -> Cmd msg


type Tree a
    = Leaf
    | Node (Tree a) a (Tree a)


main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( (), stdout (String.fromInt runDemo) )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


runDemo : Int
runDemo =
    deepestLeftA 0 (mirrorN 500 (buildTree 300000))


buildTree : Int -> Tree Int
buildTree depth =
    let
        l =
            buildLeft depth depth Leaf

        r =
            buildRight depth depth Leaf
    in
    Node l 0 r


buildLeft : Int -> Int -> Tree Int -> Tree Int
buildLeft depth value acc =
    if depth == 0 then
        acc

    else
        buildLeft (depth - 1) (value - 1) (Node acc value Leaf)


buildRight : Int -> Int -> Tree Int -> Tree Int
buildRight depth value acc =
    if depth == 0 then
        acc

    else
        buildRight (depth - 1) (value - 1) (Node Leaf value acc)


mirror : Tree a -> Tree a
mirror t =
    case t of
        Leaf ->
            Leaf

        Node l v r ->
            Node (mirror r) v (mirror l)


mirrorN : Int -> Tree a -> Tree a
mirrorN times t =
    if times == 0 then
        t

    else
        mirrorN (times - 1) (mirror t)


deepestLeftA : a -> Tree a -> a
deepestLeftA lastV t =
    case t of
        Leaf ->
            lastV

        Node l v _ ->
            deepestLeftB v l


deepestLeftB : a -> Tree a -> a
deepestLeftB lastV t =
    case t of
        Leaf ->
            lastV

        Node l v _ ->
            deepestLeftC v l


deepestLeftC : a -> Tree a -> a
deepestLeftC lastV t =
    case t of
        Leaf ->
            lastV

        Node l v _ ->
            deepestLeftA v l
