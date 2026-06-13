{- This demo program builds an immutable tree of depth 200_000, mirrors it 500
   times (causing heavy allocation pressure), and displays the deepest value on
   the left path.

   Haskell outcome: prints 200000 — all recursion shapes are stack-safe under
   GHC; allocation pressure handled by GHC's GC. Arithmetic correctness is out
   of scope — `Int32` silently wraps on under/overflow in Haskell. -}
module Main (main) where

import Data.Int (Int32)

data Tree a = Leaf | Node (Tree a) a (Tree a)

main :: IO ()
main = print runDemo

runDemo :: Int32
runDemo = deepestLeftA 0 (mirrorN 500 (buildTree 200_000))

buildTree :: Int32 -> Tree Int32
buildTree depth =
  let l = buildLeft depth depth Leaf
      r = buildRight depth depth Leaf
   in Node l 0 r

buildLeft :: Int32 -> Int32 -> Tree Int32 -> Tree Int32
buildLeft 0 _ acc = acc
buildLeft depth value acc = buildLeft (depth - 1) (value - 1) (Node acc value Leaf) -- tail recursion

buildRight :: Int32 -> Int32 -> Tree Int32 -> Tree Int32
buildRight 0 _ acc = acc
buildRight depth value acc = buildRight (depth - 1) (value - 1) (Node Leaf value acc) -- tail recursion

mirror :: Tree a -> Tree a
mirror Leaf = Leaf
mirror (Node l v r) = Node (mirror r) v (mirror l) -- multi-child non-tail recursion

mirrorN :: Int32 -> Tree a -> Tree a
mirrorN 0 t = t
mirrorN times t = mirrorN (times - 1) (mirror t) -- heavy allocation pressure

deepestLeftA :: a -> Tree a -> a
deepestLeftA lastV Leaf = lastV
deepestLeftA _ (Node l v _r) = deepestLeftB v l -- 3-node mutual tail recursion

deepestLeftB :: a -> Tree a -> a
deepestLeftB lastV Leaf = lastV
deepestLeftB _ (Node l v _r) = deepestLeftC v l -- 3-node mutual tail recursion

deepestLeftC :: a -> Tree a -> a
deepestLeftC lastV Leaf = lastV
deepestLeftC _ (Node l v _r) = deepestLeftA v l -- 3-node mutual tail recursion
