{
  runCommand,
  skills-ref,
}:
# Build an Agent Skill directory and validate it against the Agent Skills
# spec in the same build, in the spirit of pkgs.writers: the check rides on
# the artifact, so an invalid skill is never produced in the first place.
#
# name: the skill name. Must obey the spec's name rules; also becomes the
#   store name and the directory the harnesses install to.
# src: directory containing the skill files (SKILL.md, references/, ...).
name: src:
runCommand name
  {
    nativeBuildInputs = [ skills-ref ];
  }
  ''
    # skills-ref checks the directory basename against the frontmatter name,
    # and store paths carry a hash prefix, so validate a clean-named copy.
    # This is also the layout the harnesses install.
    mkdir work
    cp -r "${src}" "work/${name}"
    chmod -R u+w "work/${name}"
    skills-ref validate "work/${name}"
    cp -r "work/${name}" "$out"
  ''
