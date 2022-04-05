#!/usr/bin/env julia

using Printf
using ArgParse
using Random

include("../../../src/lib/biomath.jl")
include("../../../src/lib/constants.jl")
include("../../../src/lib/topology.jl")
include("../../../src/lib/conformation.jl")
include("../../../src/lib/parser_crd.jl")
include("../../../src/lib/parser_top.jl")

function main(args)

    top_filename = get(args, "top", "")
    crd_filename = get(args, "crd", "")
    mol_name     = get(args, "output", "new_mol")

    NUM_X = get(args, "nx", 1)
    NUM_Y = get(args, "ny", 1)
    NUM_Z = get(args, "nz", 1)

    PAD_X = get(args, "xpadding", 5.0)
    PAD_Y = get(args, "ypadding", 5.0)
    PAD_Z = get(args, "zpadding", 5.0)

    DENSE = get(args, "density", 1.0)

    ROT   = get(args, "random-rotation", false)

    mol_top = read_grotop(top_filename)
    mol_crd = read_grocrd(crd_filename)

    num_copies = Int( floor( NUM_X * NUM_Y * NUM_Z * DENSE ) )
    total_num_particles = mol_top.num_atom * num_copies

    REAL_INDICES = randperm(NUM_X * NUM_Y * NUM_Z)[1:num_copies]

    println("System name:", mol_top.system_name)
    println("Number of particles in top:", mol_top.num_atom)

    # ==============================
    # move single molecule to origin
    # ==============================
    mol_center = centroid(mol_crd.coors)
    mol_orig_coors = mol_crd.coors .- mol_center

    # ==================
    # make copies of mol
    # ==================
    max_coors = findmax(mol_orig_coors, dims=2)[1]
    min_coors = findmin(mol_orig_coors, dims=2)[1]
    MOL_SIZE = max_coors - min_coors

    gro_name = @sprintf("%s_mul_%d_%d_%d_n_%d.gro", mol_name, NUM_X, NUM_Y, NUM_Z, num_copies)
    gro_file = open(gro_name, "w")

    @printf(gro_file, "CG model %s, nx: %d, ny: %d, nz: %d, t = %16.3f \n", mol_top.system_name, NUM_X, NUM_Y, NUM_Z, 0)
    @printf(gro_file, "%12d \n", total_num_particles)

    @printf("Duplicated system has %d x %d x %d x %d%% = %d copies, in total %d atoms \n",
            NUM_X, NUM_Y, NUM_Z, Int(floor(DENSE*100)), num_copies, total_num_particles)

    i_bead_global = 0
    i_mol_global  = 0
    for ix in 1:NUM_X
        for iy in 1:NUM_Y
            for iz in 1:NUM_Z
                i_mol_global += 1
                if !( i_mol_global in REAL_INDICES )
                    continue
                end

                if ROT
                    rot_matrix = generate_random_rotation()
                    mol_coors = rot_matrix * mol_orig_coors
                else
                    mol_coors = mol_orig_coors
                end

                shift_x = (ix - 1) * (MOL_SIZE[1] + PAD_X * 2)
                shift_y = (iy - 1) * (MOL_SIZE[2] + PAD_Y * 2)
                shift_z = (iz - 1) * (MOL_SIZE[3] + PAD_Z * 2)
                for i_bead in 1 : mol_top.num_atom
                    i_bead_global += 1
                    @printf(gro_file, "%5d%5s%5s%5d %8.4f %8.4f %8.4f %8.4f %8.4f %8.4f \n",
                            mol_top.top_atoms[i_bead].residue_index,
                            mol_top.top_atoms[i_bead].residue_name,
                            mol_top.top_atoms[i_bead].atom_name,
                            i_bead_global % 100000,
                            ( mol_coors[1,i_bead] + shift_x ) * 0.1,
                            ( mol_coors[2,i_bead] + shift_y ) * 0.1,
                            ( mol_coors[3,i_bead] + shift_z ) * 0.1,
                            0.0, 0.0, 0.0)
                end
            end
        end
    end
    @printf(gro_file, "%15.4f%15.4f%15.4f \n\n", 0.0, 0.0, 0.0)

    @printf("Duplicated system size estimation (if no rotation): %16.3f x %16.3f x %16.3f \n",
            NUM_X * ( MOL_SIZE[1] + 2 * PAD_X ),
            NUM_Y * ( MOL_SIZE[2] + 2 * PAD_Y ),
            NUM_Z * ( MOL_SIZE[3] + 2 * PAD_Z ))

    close(gro_file)
end

# =============================
# Parsing Commandline Arguments
# =============================
function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin

        "--top", "-t"
        help     = "Topology file name (gromacs style)."
        required = true
        arg_type = String

        "--crd", "-c"
        help     = "Coordinate file name (gromacs style)."
        required = true
        arg_type = String

        "--output", "-o"
        help     = "Output file name."
        arg_type = String
        default  = "BIGMOL"

        "--nx"
        help     = "Number of x copies."
        arg_type = Int
        default  = 1

        "--ny"
        help     = "Number of y copies."
        arg_type = Int
        default  = 1

        "--nz"
        help     = "Number of z copies."
        arg_type = Int
        default  = 1

        "--xpadding"
        help     = "Padding distance in x axis (A)."
        arg_type = Float64
        default  = 5.0

        "--ypadding"
        help     = "Padding distance in y axis (A)."
        arg_type = Float64
        default  = 5.0

        "--zpadding"
        help     = "Padding distance in z axis (A)."
        arg_type = Float64
        default  = 5.0

        "--density"
        help     = "Density (probability) of molecules."
        arg_type = Float64
        default  = 1.0

        "--random-rotation"
        help = "Perform random rotation for each duplicate."
        action = :store_true

        "--debug"
        help = "DEBUG."
        action = :store_true
    end

    return parse_args(s)
end


if abspath(PROGRAM_FILE) == @__FILE__

    args = parse_commandline()

    main(args)

end
