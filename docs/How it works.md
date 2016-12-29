Program flow
------------

1. Try to load the cache of dependencies from `~/.elm-install/cache.json` and
   load the cache of references from `~/.elm-install/ref-cache.json`. If no
   cache files found initialize empty caches.

2. Read `dependencies` and `dependency-sources` from `elm-package.json` and
   transform them from:

   ```
   {
     "dependencies": {
       "elm-lang/core": "5.0.0 <= 6.0.0",
       "gdotdesign/elm-ui": "1.0.0 <= 2.0.0"
     },
     "dependency-sources": {
       "gdotdesign/elm-ui": {
         "url": "git@bitbucket.com:gdotdesign/elm-ui",
         "ref": "development"
       }
     }
   }
   ```

   to:

   ```
   {
     "https://github.com/elm-lang/core": "5.0.0 <= 6.0.0",
     "git@bitbucket.com:gdotdesign/elm-ui": "development"
   }
   ```

3. Add dependencies to the cache, skipping if the package is already added.

4. Solved dependencies from the cache.

5. (If no solution found) Go through the packages from the cache and update
   their references and if it changed update the repository (fetching new
   content)

6. (If no solution found) Solve dependencies from the updated cache.

7. Save cache.

8. (If solution found) Populate `elm-stuff` and write
   `elm-stuff/exact-dependecies.json`
