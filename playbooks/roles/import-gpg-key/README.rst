import-gpg-key

Import a gpg ASCII armored public key to the local keystore.

**Role Variables**

.. zuul:rolevar:: gpg_key_id

   The ID of the key to import.  If it already exists, the file is not
   imported.

.. zuul:rolevar:: gpg_key_asc

   The path of the ASCII armored GPG key to import
