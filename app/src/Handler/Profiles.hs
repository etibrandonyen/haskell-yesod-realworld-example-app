{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Handler.Profiles
  ( getProfilesR
  , postFollowR
  , deleteFollowR
  )
  where

import           Data.Aeson
import           Import


--------------------------------------------------------------------------------
-- Get Profile

getProfilesR :: Text -> Handler Value
getProfilesR username = do
  (Entity userId user) <- runDB $ getBy404 $ UniqueUserUsername username
  mCurrentUserId <- maybeAuthId
  following <-
    case mCurrentUserId of

      Just currentUserId ->
        isJust <$> runDB (getBy $ UniqueUserFollower userId currentUserId)

      _ ->
        return False

  return $ encodeProfile user following

encodeProfile :: User -> Bool -> Value
encodeProfile User {..} following =
  object
    [ "profile" .= object
        [ "username" .= userUsername
        , "bio" .= userBio
        , "image" .= userImage
        , "following" .= following
        ]
    ]

--------------------------------------------------------------------------------
-- Follow User

postFollowR :: Text -> Handler Value
postFollowR username = do
  (Entity userId _) <- runDB $ getBy404 $ UniqueUserUsername username
  Just currentUserId <- maybeAuthId
  let follower = UserFollower userId currentUserId
  conflict <- runDB $ checkUnique follower
  case conflict of
    Just _ -> return ()
    _ -> runDB $ insert_ follower
  getProfilesR username
  

--------------------------------------------------------------------------------
-- Unfollow User

deleteFollowR :: Text -> Handler Value
deleteFollowR username = do
  (Entity userId _) <- runDB $ getBy404 $ UniqueUserUsername username
  Just currentUserId <- maybeAuthId
  runDB $ deleteBy $ UniqueUserFollower userId currentUserId
  getProfilesR username
