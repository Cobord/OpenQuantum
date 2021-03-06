{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module MyGrouDits
( Groupoid,
  FiniteGroudit,
  DisjointFormFiniteGroupoid
) where

import Data.Maybe
import System.Random
import Data.List
import MyGroups
import CopyShuffle as CopiedS

-- https://arxiv.org/pdf/1707.00966.pdf --

data ObjectSet1 = Slot0 deriving (Eq,Show,Read,Enum,Bounded)
data ObjectSet2 = Slot1 | Slot2 deriving (Eq,Show,Read,Enum,Bounded)
data ObjectSet5 = SlotA | SlotB | SlotC | SlotD | SlotE deriving (Eq,Show,Read,Enum,Bounded)
data ObjectSet6 = Slot012 | Slot021 | Slot102 | Slot120 | Slot201 | Slot210 deriving (Eq,Show,Read,Enum,Bounded)

-- the general groupoid where the set of objects is b
-- the a itself stores the arrows
-- when passing (a,b) that is meant to be an arrow a
-- and that the source for that arrow is the second of that tuple
class Groupoid a b where
    groupoidmult :: (a,b) -> (a,b) -> Maybe (a,b)
    groupoidinv :: (a,b) -> (a,b)
    identityMorphisms :: b -> (a,b)
    sourceObject :: (a,b) -> b
    targetObject :: (a,b) -> b

instance (FiniteGroup a) => (Groupoid a ObjectSet1) where
    groupoidmult (x1,x2) (y1,y2) = Just ((mult x1 y1),x2)
    groupoidinv (x1,x2) = (inv x1,x2)
    identityMorphisms x2 = (identity,x2)
    sourceObject (_,x2) = x2
    targetObject (_,x2) = x2

leftHelper :: Maybe (a,b) -> Maybe (Either a c,Either b d)
leftHelper Nothing = Nothing
leftHelper temp = Just (Left (fst $ fromJust temp),Left (snd $ fromJust temp))
rightHelper :: Maybe (a,b) -> Maybe (Either c a,Either d b)
rightHelper Nothing = Nothing
rightHelper temp =Just (Right (fst $ fromJust temp),Right (snd $ fromJust temp))

instance (Bounded b,Bounded d) => Bounded (Either b d) where
    minBound = Left minBound
    maxBound = Right maxBound

-- disjoint union of two groupoids, one with arrows a on objects c and another with b and d
instance (Groupoid a b,Groupoid c d) => Groupoid (Either a c) (Either b d) where
    groupoidmult (Left x,Left y) (Left z,Left w) = leftHelper (groupoidmult (x,y) (z,w))
    groupoidmult (Right x,Right y) (Right z,Right w) = rightHelper (groupoidmult (x,y) (z,w))
    groupoidmult _ _ = Nothing
    identityMorphisms (Left x) = do let temp=(identityMorphisms x) in (Left (fst temp),Left (snd temp))
    identityMorphisms (Right x) = do let temp=(identityMorphisms x) in (Right (fst temp),Right (snd temp))
    sourceObject (Left x1,Left x2) = Left (sourceObject (x1,x2))
    sourceObject (Right x1,Right x2) = Right (sourceObject (x1,x2))
    targetObject (Left x1,Left x2) = Left (targetObject (x1,x2))
    targetObject (Right x1,Right x2) = Right (targetObject (x1,x2))
    groupoidinv (Left x1,Left x2) = do let temp=groupoidinv (x1,x2) in (Left (fst temp),Left (snd temp))
    groupoidinv (Right x1,Right x2) = do let temp=groupoidinv (x1,x2) in (Right (fst temp),Right (snd temp))

-- list of a's, a function f to b's, a y that is desired and a default value
-- then select the first of that list such that f(x)=y
selectFirstMeetingCriteria :: (Eq b) => [a] -> (a -> b) -> b -> a -> a
selectFirstMeetingCriteria [] _ _ defaultVal = defaultVal
selectFirstMeetingCriteria (x:xs) f myB defaultVal = if (f x == myB) then x else (selectFirstMeetingCriteria xs f myB defaultVal)
-- just swap
mySwap :: (a,b) -> (b,a)
mySwap (x,y) = (y,x)

-- put some shuffling function here with first argument being the list to shuffle
-- the second the length and the third a source of randomness
my_shuffle :: (RandomGen gen) => [a] -> Int -> gen -> [a]
my_shuffle = CopiedS.shuffle'
myShuffle :: (RandomGen gen,Bounded b,Enum b,Eq b) => gen -> b -> b
myShuffle g x = (my_shuffle y (length y) g)!!(fromJust $ elemIndex x y) where y=[minBound..maxBound]
myShuffle2 :: (Bounded b,Enum b,Eq b) => Int -> b -> b
myShuffle2 z = myShuffle (mkStdGen z)

class (FiniteGroup a,Eq b) => DisjointFormFiniteGroupoid a b where
    df_groupoidmult :: (a,b) -> (a,b) -> Maybe (a,b)
    df_groupoidinv :: (a,b) -> (a,b)
    df_identityMorphisms :: b -> (a,b)
    df_sourceObject :: (a,b) -> b
    df_targetObject :: (a,b) -> b
    df_giPart :: (a,b) -> a
instance (FiniteGroup a,Eq b) => DisjointFormFiniteGroupoid a b where
    df_groupoidmult (x,y) (z,w)
                            | y==w = Just (mult x z,y)
                            | otherwise = Nothing
    df_groupoidinv (x,y) = (inv x,y)
    df_identityMorphisms y = (identity , y)
    df_sourceObject (x,y) = y
    df_targetObject (x,y) = y
    df_giPart (x,y) = x
-- a general groupoid might be a grouDit if you provide extra data

-- should be from import Data.Types.Isomorphic
class Iso a b where
    to :: a -> b
instance Iso CyclicGroup2 ObjectSet2 where
    to x = ([(minBound)..(maxBound)])!!(fromJust $ elemIndex x y) where y=[(minBound)..(maxBound)]
instance Iso CyclicGroup5 ObjectSet5 where
    to x = ([(minBound)..(maxBound)])!!(fromJust $ elemIndex x y) where y=[(minBound)..(maxBound)]
class (DisjointFormFiniteGroupoid a b,Iso a b,Bounded a,Bounded b,Enum a,Enum b) => FiniteGroudit a b where
    --Pair of balancers sigma and tau that give bijections G_i with Obj(G)
    -- the second of the pair is the i, the first is an element of G_i they are bijections to Obj(G) which is the set of b
    sigma :: (a,b) -> b
    tau :: (a,b) -> b
    -- sigmaInverse x y = (z,x) such that sigma((z,x))=y
    -- ordered this way so that (sigmaInverse x) as a function b -> (a,b) would be ( sigma_x^{-1} ? , x)
    sigmaInverse :: b -> b -> (a,b)
    -- tauInverse x y = (z,x) such that tau((z,x))=y
    tauInverse :: b -> b -> (a,b)
    sigma1 :: (a,b) -> (b,b)
    sigma2 :: (b,b) -> (a,b)
    -- sigma2 sigma1 (x,y) = sigma2 (y,sigma (x,y)) = (z,y) with sigma((z,y))=sigma (x,y) = (x,y)
    -- same pattern but with tau
    tau1 :: (a,b) -> (b,b)
    tau2 :: (b,b) -> (a,b)
    -- From these balancers contstruct biunitary
    biunitary :: (a,b) -> (a,b)
instance (Enum b,Enum a,Bounded a,Bounded b,Iso a b,DisjointFormFiniteGroupoid a b) => (FiniteGroudit a b) where
    sigma (x,y)=myShuffle2 (fromEnum y) (to x)
    tau (x,y) = myShuffle2 (-1-fromEnum y) (to x)
    sigmaInverse x y = selectFirstMeetingCriteria allPossible sigma y (head allPossible) where allPossible = [(z,x)| z <- [minBound..maxBound]]
    tauInverse x y = selectFirstMeetingCriteria allPossible tau y (head allPossible) where allPossible = [(z,x)| z <- [minBound..maxBound]]
    sigma1 (x,y) = (y,sigma (x,y))
    tau1 (x,y) = (y,tau (x,y))
    sigma2 (x,y) = sigmaInverse x y
    tau2 (x,y) = tauInverse x y
    biunitary (x,y) = tau2 $ mySwap $ sigma1 (x,y)

-- if you did sigma (RotFour,Slot021) it would give the error that there is no instance of Iso between CyclicGroup5 and ObjectSet6
-- that would not be appplicable for a finite groudit, but below with CyclicGroup5 and ObjectSet5 is fine
example = sigma (RotFour,SlotD)