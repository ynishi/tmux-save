{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import qualified Control.Foldl as F
import qualified Data.Text as T
import System.Environment
import System.FilePath as P
import Turtle as Tu hiding ((</>))

run cmd args = fold (inproc cmd args empty) F.list
txt = T.concat . map lineToText

tmuxData home = home </> ".tmux/resurrect"
tmuxLast home = home </> ".tmux/resurrect/last"
getScriptDir home = home </> ".tmux/plugins/tmux-resurrect/scripts"

main :: IO ()
main = do
    args <- getArgs
    let sub = head args
    let name = args !! 1
    print name
    home <- getEnv "HOME"
    print home
    let tmuxLast' = T.pack $ tmuxLast home
    before <- run "readlink" [tmuxLast']
    let before' = txt before
    print before'
    let scriptDir = getScriptDir home
    f <- case sub of
        "save" -> return save
        "restore" -> return restore
        _ -> return noop
    f name home before' tmuxLast' scriptDir

noop name home before tmuxLast scriptDir = do
    print "do nothing"

restore name home before tmuxLast scriptDir = do
    pwd <- getEnv "PWD"
    run "rm" ["-f", tmuxLast]
    run "ln" ["-s", T.pack $ pwd </> name, tmuxLast]
    run "bash" [T.pack $ scriptDir </> "restore.sh"]
    run "rm" ["-f", tmuxLast]
    run "ln" ["-s", before, tmuxLast]
    print "restored!"

save name home before tmuxLast scriptDir = do
    run "bash" [T.pack $ scriptDir </> "save.sh"]
    after <- run "readlink" [tmuxLast]
    let after' = txt after
    run "mv" ["-v", T.pack (tmuxData home) <> "/" <> after', T.pack name]
    run "rm" ["-f", tmuxLast]
    run "ln" ["-s", before, tmuxLast]
    print "saved!"
