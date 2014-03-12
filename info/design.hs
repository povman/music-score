

{-# LANGUAGE NoMonomorphismRestriction, TypeFamilies, FlexibleContexts, ConstraintKinds #-}

import Diagrams.Prelude hiding (Time, Duration, (|>), stretch)
import qualified Diagrams.Backend.SVG as SVG

-- test       
import Music.Prelude.Basic hiding (pitch)
import qualified Music.Pitch as P
import qualified Music.Score as S

import Data.VectorSpace
import Data.AffineSpace
-- import Data.Semigroup
import Control.Lens hiding ((|>))
import System.Process
import Text.Blaze.Svg.Renderer.Utf8 (renderSvg)
import qualified Data.ByteString.Lazy as ByteString


-- TODO
type instance S.Pitch (ChordT a) = S.Pitch a
instance HasGetPitch a => HasGetPitch (ChordT a) where
    __getPitch (ChordT xs) = __getPitch $ head $ xs

timeToDouble :: Time -> Double
timeToDouble = realToFrac . (.-. origin)
durationToDouble :: Duration -> Double
durationToDouble = realToFrac
pitchToDouble :: P.Pitch -> Double
pitchToDouble = realToFrac . semitones . (.-. c)

drawScore :: (Renderable (Path R2) b, Real a) => Score a -> Diagram b R2
drawScore = {-bg whitesmoke .-} scaleX 1{-TODO-} . mconcat . 
    fmap drawScoreNote . 
    fmap (map1 timeToDouble . map2 durationToDouble . map3 realToFrac) . 
    (^. events)
    where
        map1 f (a,b,c) = (f a,b,c)
        map2 f (a,b,c) = (a,f b,c)
        map3 f (a,b,c) = (a,b,f c)
        drawScoreNote (t,d,x) = translateY x $ translateX (t.+^(d^/2)) $ scaleX d $ noteShape
        noteShape = lcA transparent $ fcA (blue `withOpacity` 0.5) $ square 1

-- TODO
drawBeh :: (Renderable (Path R2) b, Real a) => Behavior a -> Diagram b R2
drawBeh = const $ circle 1



main = openGraphic $ drawScore $ fmap (semitones.(.-. c).__getPitch) $ score1

score1 :: Score Note
score1 = rcat [
    up _P5 $ stretch 2 $ scat $ fmap motive $ [1..5],
    up _M3 $ stretch 3 $ scat $ fmap motive $ [1..4],
    up _P1 $ stretch 4 $ scat $ fmap motive $ [1..3]
    ]
    where
        motive n = legato $ {-pitches %~ id $-} times (n+1) (scat [c..e]) |> times n (scat [d..f])







writeGraphic :: (Renderable (Path R2) b, b ~ SVG.SVG) => FilePath -> Diagram b R2 -> IO ()
writeGraphic path dia = do
    let svg = renderDia SVG.SVG (SVG.SVGOptions (Height 300) Nothing) dia
    let bs  = renderSvg svg
    ByteString.writeFile path bs
        
openGraphic dia = do
    writeGraphic "test.svg" $ dia -- 
    -- FIXME find best reader
    system "echo '<img src=\"test.svg\"></img>' > test.html"
    system "open -a 'Firefox' test.html"
    return ()