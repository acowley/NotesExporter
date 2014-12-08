{-# LANGUAGE OverloadedStrings #-}
-- | Looks for a Notes.app SQLite3 database in the file
-- @data/NotesV3.storedata@, and outputs a series of note files to a
-- directory @notes@ in the current working directory. In OS X
-- Yosemite, the Notes.app database may be found in
-- @~/Library/Containers/com.apple.Notes/Data/Library/Notes/@. Make a
-- directory @data@ in your current working directory, and copy all
-- files from the @Notes@ directory to this @data@ directory. This way
-- you have a backup of the database itself, as well as the extracted
-- note text.
import Data.Char (isAlphaNum)
import Data.Monoid ((<>))
import Data.Text.Lazy (Text)
import qualified Data.Text.Lazy as T
import qualified Data.Text.Lazy.IO as T
import Database.SQLite.Simple
import Formatting
import System.Directory (createDirectory, doesDirectoryExist, doesFileExist)
import System.FilePath ((</>), (<.>))

data Note = Note { noteTitle :: Text
                 , noteBody  :: Text }
            deriving Show

dbName :: String
dbName = "data/NotesV3.storedata"

main :: IO ()
main = do conn <- open dbName
          r <- query_ conn ("select ZHTMLSTRING from ZNOTEBODY") :: IO [Only Text]
          d <- noteDir
          createDirectory d
          mapM_ (saveNote d . parseNote . fromOnly) r
          close conn

eatSpan :: Text -> Text
eatSpan = T.replace "</span>" ""
        . T.concat
        . map' (T.tail . T.dropWhile (/= '>'))
        . T.splitOn "<span"
  where map' _ [] = []
        map' f (h:t) = h : map f t

parseNote :: Text -> Note
parseNote = aux . T.lines . cleanup
  where aux [] = Note "" ""
        aux (h:body) = Note h (T.unlines body)
        cleanup = T.strip
                . eatSpan
                . T.replace "<br>" "\n"
                . T.replace "<div>" "\n"
                . T.replace "</div>" ""
                . T.replace "&nbsp;" " "

-- | Find an unused directory name to store extracted notes.
noteDir :: IO FilePath
noteDir = go 0
  where go :: Int -> IO FilePath
        go 0 = do e <- doesDirectoryExist "notes"
                  if e then go 1 else return "notes"
        go n = let d = T.unpack $ format ("notes" % left 2 '0') n
               in do e <- doesDirectoryExist d
                     if e then go (n+1) else return d

-- | Replace all non-alphanumeric characters in a note title with
-- underscore characters, and take only the first 20 characters of the
-- result.
sanitizeName :: Text -> Text
sanitizeName = T.take 20 . T.intercalate "_" . filter (not . T.null)
             . T.split (not . isAlphaNum)

-- | @noteName dir noteTitle@ ensure we have a unique file name for a
-- note based on its title. If two notes have the same title, the
-- second's file name is appended with \"(2)\".
noteFile :: FilePath -> Text -> IO FilePath
noteFile dir title = go 0
  where t = T.unpack (sanitizeName title)
        go :: Int -> IO FilePath
        go 0 = let p = dir </> t <.> "txt"
               in do e <- doesFileExist p
                     if e then go 1 else return p
        go i = let p = dir </> (t ++ "("++show i++")") <.> "txt"
               in do e <- doesFileExist p
                     if e then go (i+1) else return p

-- | Write a 'Note' to a file.
saveNote :: FilePath -> Note -> IO ()
saveNote dir n = do f <- noteFile dir (noteTitle n)
                    T.writeFile f (noteTitle n <> "\n\n" <> noteBody n)
