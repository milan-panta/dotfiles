module Main where

square :: Int -> Int
square x = x * x

total :: [Int] -> Int
total = sum . map square

main :: IO ()
main = print (total [1, 2, 3])
