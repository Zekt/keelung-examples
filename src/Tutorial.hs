{-# LANGUAGE DataKinds #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}

{-# HLINT ignore "Use <$>" #-}
{-# HLINT ignore "Redundant return" #-}

module Tutorial where

import qualified BLAKE2b
import Control.Monad
import Keelung
import qualified Lib.Array as Array
import qualified Lib.W8 as W8

-- | Outputs whether number is given.
echo :: Comp Number
echo = do
  x <- input -- request for an input and bind it to 'x'
  return x -- return 'x'

-- | A program that expects 2 inputs and returns no output
useless :: Comp Unit
useless = do
  x <- inputNum -- request for an input and bind it to 'x'
  y <- inputBool -- request for an input and bind it to 'y'
  return unit -- return nothing

-- | A program that expects the second input
-- to be the square of the first input
square :: Comp Unit
square = do
  x <- input -- request for an input and bind it to 'x'
  y <- input -- request for an input and bind it to 'y'
  assert ((x * x) `Eq` y) -- assert that 'y' is the square of 'x'
  return unit -- return nothing

-- | A program that converts between Celsius and Fahrenheit degrees
tempConvert :: Comp Number
tempConvert = do
  toFahrenheit <- input -- Bool
  degree <- input -- Num
  return $
    cond
      toFahrenheit
      (degree * 9 / 5 + 32)
      (degree - 32 * 5 / 9)

-- | Read out the 4th input from an array of 10 inputs
fourthInput :: Comp Number
fourthInput = do
  xs <- inputs 10
  let fourth = access xs 3
  return fourth

-- | A program that asserts all 10 inputs to be 42
allBe42 :: Comp Unit
allBe42 = do
  xs <- inputs 10
  -- access elements of `xs` with indices
  forM_ [0 .. 9] $ \i -> assert (access xs i `Eq` 42)
  -- access elements of `xs` directly
  forM_ (fromArray xs) $ \x -> assert (x `Eq` 42)
  return unit

-- | A program that sums all the 10 inputs
summation :: Comp Number
summation = do
  xs <- inputs 10
  return $ sum (fromArray xs)

returnArray :: Comp (Arr Number)
returnArray = do
  x <- input
  return $ toArray [x, x, x, x]

-- > interpret (blake2b 2 3) [1,0,0,0,0,1,1,0, 0,1,0,0,0,1,1,0]
--   Right [10110010 11101100 00100010]
--
-- means to calculate the 3-byte digest blake2b of string "ab"
-- a = 0b01100001, b = 0b01000010
-- the answer is Blake2b-24("ab") = 0x4d3744, which is
-- 0b01001101, 0b00110111, 0b1000100
blake2b :: Int -> Int -> Comp (ArrM (ArrM Boolean))
blake2b msglen hashlen = do
  msg <- inputs2 msglen 8 >>= thaw2
  BLAKE2b.hash msg msglen hashlen

-- | Birthday voucher example
birthday :: Comp Boolean
birthday = do
  -- these inputs are private witnesses
  _hiddenYear <- inputNum
  hiddenMonth <- input
  hiddenDate <- input
  -- these inputs are public inputs
  month <- input
  date <- input

  return $ (hiddenMonth `Eq` month) `And` (hiddenDate `Eq` date)

-- | A program that outputs the input to the 4th power (without computation reusing)
notReused :: Comp (Arr Number)
notReused = do
  x <- input
  let y = x * x * x * x
  return $ toArray [y, y]

-- | A program that outputs the input to the 4th power (with computation reusing)
reused :: Comp (Arr Number)
reused = do
  x <- input
  y <- reuse $ x * x * x * x
  return $ toArray [y, y]