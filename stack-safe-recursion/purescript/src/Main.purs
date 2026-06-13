{-| This program builds an immutable tree of depth `treeDepth`, mirrors it
`mirrorCount` times, and prints the deepest value on the left path. Both are
read from argv; the recorded run (assert-behavior.sh) passes `5000000 1`.

PureScript outcome (`npm start -- 5000000 1`): `RangeError: Maximum call stack size exceeded` inside
`mirror` on the very first call. `Node (mirror r) v (mirror l)` is multi-child
non-tail self-recursion — `purs` emits a JS `while` loop only for
self-recursive *tail* calls, so the depth-5_000_000 V-tree exhausts the JS
engine's call stack before any output is produced. `deepestLeftA/B/C` would
similarly overflow if reached, because PureScript doesn't optimize mutual tail
recursion either.
-}
module Main (main) where

import Prelude

import Effect (Effect)
import Effect.Console (log)

data Tree a = Leaf | Node (Tree a) a (Tree a)

foreign import treeDepthImpl :: Effect Int
foreign import mirrorCountImpl :: Effect Int

main :: Effect Unit
main = do
  treeDepth <- treeDepthImpl
  mirrorCount <- mirrorCountImpl
  log (show (runDemo treeDepth mirrorCount))

runDemo :: Int -> Int -> Int
runDemo treeDepth mirrorCount = deepestLeftA 0 (mirrorN mirrorCount (buildTree treeDepth))

buildTree :: Int -> Tree Int
buildTree depth =
  let
    l = buildLeft depth depth Leaf
    r = buildRight depth depth Leaf
  in
    Node l 0 r

buildLeft :: Int -> Int -> Tree Int -> Tree Int
buildLeft 0 _ acc = acc
buildLeft depth value acc = buildLeft (depth - 1) (value - 1) (Node acc value Leaf) -- tail recursion

buildRight :: Int -> Int -> Tree Int -> Tree Int
buildRight 0 _ acc = acc
buildRight depth value acc = buildRight (depth - 1) (value - 1) (Node Leaf value acc) -- tail recursion

mirror :: forall a. Tree a -> Tree a
mirror Leaf = Leaf
mirror (Node l v r) = Node (mirror r) v (mirror l) -- multi-child non-tail recursion

mirrorN :: forall a. Int -> Tree a -> Tree a
mirrorN 0 t = t
mirrorN times t = mirrorN (times - 1) (mirror t) -- tail recursion

deepestLeftA :: forall a. a -> Tree a -> a
deepestLeftA lastV Leaf = lastV
deepestLeftA _ (Node l v _) = deepestLeftB v l -- 3-node mutual tail recursion

deepestLeftB :: forall a. a -> Tree a -> a
deepestLeftB lastV Leaf = lastV
deepestLeftB _ (Node l v _) = deepestLeftC v l -- 3-node mutual tail recursion

deepestLeftC :: forall a. a -> Tree a -> a
deepestLeftC lastV Leaf = lastV
deepestLeftC _ (Node l v _) = deepestLeftA v l -- 3-node mutual tail recursion
